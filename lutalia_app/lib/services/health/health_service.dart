import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/health_day_summary.dart';
import '../../utils/sleep_window.dart';
import 'health_permission_bridge.dart';

/// Which of Lutalia's two data kinds the platform currently lets us read.
class HealthAccess {
  const HealthAccess({
    required this.steps,
    required this.sleep,
    this.determinate = true,
  });

  const HealthAccess.none() : steps = false, sleep = false, determinate = true;

  final bool steps;
  final bool sleep;

  /// False on iOS: HealthKit never discloses READ grants for privacy, so
  /// "granted" there only means the authorization sheet was completed.
  final bool determinate;

  bool get hasAny => steps || sleep;
  bool get isFull => steps && sleep;
  bool get isPartial => determinate && hasAny && !isFull;
}

/// Platform health source: Apple HealthKit on iOS, Health Connect on Android
/// (Samsung Health, Google Fit, Fitbit, … sync into Health Connect).
///
/// Read-only. Every method is safe to call on any platform and never throws;
/// unsupported platforms simply report nothing.
class HealthService {
  HealthService._();

  static final HealthService instance = HealthService._();

  final Health _health = Health();
  bool _configured = false;

  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static const Duration _sleepLookBack = Duration(hours: 12);

  HealthDataSource get source =>
      _isIOS ? HealthDataSource.appleHealth : HealthDataSource.healthConnect;

  /// HealthKit has no session record, only per-stage samples (iOS 16+:
  /// core = SLEEP_LIGHT). IN_BED is the fallback for iPhones without a watch.
  /// Asking a platform for a type it lacks makes the plugin throw, so each
  /// platform gets only its own list.
  static List<HealthDataType> get _sleepTypes => _isIOS
      ? const <HealthDataType>[
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_REM,
          HealthDataType.SLEEP_AWAKE,
          HealthDataType.SLEEP_IN_BED,
        ]
      : const <HealthDataType>[
          HealthDataType.SLEEP_SESSION,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_REM,
          HealthDataType.SLEEP_AWAKE,
          HealthDataType.SLEEP_AWAKE_IN_BED,
        ];

  static List<HealthDataType> get _types => <HealthDataType>[
    HealthDataType.STEPS,
    ..._sleepTypes,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// iOS always has HealthKit. Android asks Health Connect directly, because
  /// the plugin's own check can miss the provider due to package visibility.
  Future<HealthAvailability> availability() async {
    if (!isSupportedPlatform) return HealthAvailability.unknown;
    if (_isIOS) return HealthAvailability.available;
    final HealthAvailability native =
        await HealthPermissionBridge.availability();
    if (native != HealthAvailability.unknown) return native;
    try {
      return await _health.isHealthConnectAvailable()
          ? HealthAvailability.available
          : HealthAvailability.notInstalled;
    } catch (_) {
      return HealthAvailability.unknown;
    }
  }

  /// Shows the system permission sheet for whatever is still missing.
  /// Returns true when a sheet was shown and completed; the real outcome must
  /// still be verified with [access] or an actual read.
  Future<bool> requestAuthorization() async {
    if (!isSupportedPlatform) return false;
    try {
      await _ensureConfigured();
      if (!_isIOS) {
        final Set<String> missing = await _missingAndroidPermissions();
        if (missing.isEmpty) return true;
        if (await HealthPermissionBridge.request(missing) != null) return true;
      }
      // iOS, or Android without the native bridge. HealthKit only shows the
      // sheet for types it has never asked about, so repeat calls are silent.
      return await _health.requestAuthorization(
        _types,
        permissions: List<HealthDataAccess>.filled(
          _types.length,
          HealthDataAccess.READ,
        ),
      );
    } catch (e) {
      HealthPermissionBridge.log('requestAuthorization failed: $e');
      return false;
    }
  }

  Future<Set<String>> _missingAndroidPermissions() async {
    final Set<String> all = <String>{
      for (final HealthConnectPermission p
          in HealthPermissionBridge.permissions)
        p.permission,
    };
    final Set<String>? granted = await HealthPermissionBridge.granted();
    if (granted == null) return all;
    return all.difference(granted);
  }

  /// Current read access, resolved without ever prompting.
  ///
  /// [iosAuthorized] is the app's own record that the HealthKit sheet was
  /// completed, since iOS cannot be asked.
  Future<HealthAccess> access({required bool iosAuthorized}) async {
    if (!isSupportedPlatform) return const HealthAccess.none();
    if (_isIOS) {
      return HealthAccess(
        steps: iosAuthorized,
        sleep: iosAuthorized,
        determinate: false,
      );
    }
    final Set<String>? granted = await HealthPermissionBridge.granted();
    if (granted != null) {
      return HealthAccess(
        steps: granted.contains(HealthPermissionBridge.stepsPermission),
        sleep: granted.contains(HealthPermissionBridge.sleepPermission),
      );
    }
    try {
      await _ensureConfigured();
      return HealthAccess(
        steps: await _hasRead(HealthDataType.STEPS),
        sleep: await _hasRead(HealthDataType.SLEEP_SESSION),
      );
    } catch (_) {
      return const HealthAccess.none();
    }
  }

  Future<bool> _hasRead(HealthDataType type) async {
    try {
      return await _health.hasPermissions(
            <HealthDataType>[type],
            permissions: <HealthDataAccess>[HealthDataAccess.READ],
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Health Connect's own permission screen on Android, the app's settings
  /// page on iOS (Health permissions live under Settings › Health › Lutalia).
  Future<bool> openPermissionSettings() async {
    if (!isSupportedPlatform) return false;
    if (await HealthPermissionBridge.openSettings()) return true;
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Play Store listing for Health Connect (Android 13 and lower).
  Future<bool> installHealthConnect() async {
    if (!HealthPermissionBridge.isSupported) return false;
    if (await HealthPermissionBridge.installProvider()) return true;
    try {
      await _health.installHealthConnect();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Total steps in `[start, end)`. Uses the platform's aggregate, which
  /// already de-duplicates a phone and a watch counting the same steps;
  /// falls back to summing raw samples (which may over-count).
  Future<int?> readSteps(DateTime start, DateTime end) async {
    if (!isSupportedPlatform || !end.isAfter(start)) return null;
    try {
      await _ensureConfigured();
    } catch (_) {
      return null;
    }
    try {
      final int? total = await _health.getTotalStepsInInterval(start, end);
      if (total != null) return total;
    } catch (e) {
      HealthPermissionBridge.log('steps aggregate failed: $e');
    }
    try {
      final List<HealthDataPoint> points = _health.removeDuplicates(
        await _health.getHealthDataFromTypes(
          startTime: start,
          endTime: end,
          types: const <HealthDataType>[HealthDataType.STEPS],
        ),
      );
      if (points.isEmpty) return null;
      num steps = 0;
      for (final HealthDataPoint p in points) {
        final HealthValue value = p.value;
        if (value is NumericHealthValue) steps += value.numericValue;
      }
      return steps.round();
    } catch (e) {
      HealthPermissionBridge.log('steps samples failed: $e');
      return null;
    }
  }

  /// Daily step totals for the last [days] days, oldest first, today last.
  /// Missing days are null (no access or nothing recorded).
  Future<List<({DateTime day, int? steps})>> readDailySteps(int days) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<DateTime> dayStarts = <DateTime>[
      for (int i = days - 1; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];
    final List<int?> totals = await Future.wait(
      dayStarts.map((DateTime start) {
        final DateTime next = DateTime(start.year, start.month, start.day + 1);
        return readSteps(start, next.isAfter(now) ? now : next);
      }),
    );
    return <({DateTime day, int? steps})>[
      for (int i = 0; i < dayStarts.length; i++)
        (day: dayStarts[i], steps: totals[i]),
    ];
  }

  /// The night that belongs to [day] (18:00 the evening before → 18:00).
  /// Null when nothing was recorded or access is missing.
  Future<SleepSummary?> readSleep(DateTime day) async {
    if (!isSupportedPlatform) return null;
    try {
      await _ensureConfigured();
    } catch (_) {
      return null;
    }
    final ({DateTime start, DateTime end}) window = sleepReadWindow(day);
    if (!window.end.isAfter(window.start)) return null;

    // HealthKit only returns samples that *start* inside the query range
    // (strictStartDate), so a night beginning before the window would vanish.
    // Query earlier and let summarizeSleep clip to the window instead.
    final DateTime queryStart = window.start.subtract(_sleepLookBack);

    // Read type by type so one unsupported/denied stage never drops the rest.
    final Map<HealthDataType, List<TimeInterval>> byType =
        <HealthDataType, List<TimeInterval>>{};
    for (final HealthDataType type in _sleepTypes) {
      try {
        final List<HealthDataPoint> points = await _health
            .getHealthDataFromTypes(
              startTime: queryStart,
              endTime: window.end,
              types: <HealthDataType>[type],
            );
        if (points.isEmpty) continue;
        for (final HealthDataPoint p in points) {
          HealthPermissionBridge.log(
            'sleep sample ${type.name} '
            '${p.dateFrom.toIso8601String()}..${p.dateTo.toIso8601String()} '
            'source=${p.sourceName} method=${p.recordingMethod.name}',
          );
        }
        byType[type] = <TimeInterval>[
          for (final HealthDataPoint p in points)
            (from: p.dateFrom, to: p.dateTo),
        ];
      } catch (e) {
        HealthPermissionBridge.log('sleep ${type.name} failed: $e');
      }
    }
    final SleepSummary? summary = summarizeSleep(
      byType,
      start: window.start,
      end: window.end,
    );
    HealthPermissionBridge.log(
      'sleep ${window.start.toIso8601String()}..${window.end.toIso8601String()} '
      'types=${byType.keys.map((HealthDataType t) => t.name).join(",")} '
      'asleep=${summary?.asleepMinutes} deep=${summary?.deepMinutes} '
      'rem=${summary?.remMinutes} awake=${summary?.awakeMinutes}',
    );
    return summary;
  }
}

/// Turns raw per-type sleep intervals into one night. Pure, so it is easy to
/// unit test.
///
/// * Asleep = union of every "asleep" stage (unspecified/light/deep/REM).
/// * Without stages: Health Connect session minus awake stages, or HealthKit
///   in-bed time as the last resort.
/// * Stage minutes are null when the source recorded no stages at all.
@visibleForTesting
SleepSummary? summarizeSleep(
  Map<HealthDataType, List<TimeInterval>> byType, {
  required DateTime start,
  required DateTime end,
}) {
  List<TimeInterval> of(HealthDataType t) =>
      byType[t] ?? const <TimeInterval>[];
  int minutes(Iterable<TimeInterval> i) =>
      mergedMinutes(i, start: start, end: end);

  final List<TimeInterval> light = of(HealthDataType.SLEEP_LIGHT);
  final List<TimeInterval> deep = of(HealthDataType.SLEEP_DEEP);
  final List<TimeInterval> rem = of(HealthDataType.SLEEP_REM);
  final List<TimeInterval> awake = <TimeInterval>[
    ...of(HealthDataType.SLEEP_AWAKE),
    ...of(HealthDataType.SLEEP_AWAKE_IN_BED),
  ];
  final List<TimeInterval> asleepStages = <TimeInterval>[
    ...of(HealthDataType.SLEEP_ASLEEP),
    ...light,
    ...deep,
    ...rem,
  ];

  int asleep = minutes(asleepStages);
  if (asleep == 0) {
    final List<TimeInterval> session = of(HealthDataType.SLEEP_SESSION);
    if (session.isNotEmpty) {
      asleep = minutes(session) - minutes(awake);
    } else {
      asleep = minutes(of(HealthDataType.SLEEP_IN_BED));
    }
  }
  if (asleep <= 0) return null;

  final List<TimeInterval> everything = mergeIntervals(
    byType.values.expand((List<TimeInterval> l) => l),
    start: start,
    end: end,
  );
  final bool hasStages = light.isNotEmpty || deep.isNotEmpty || rem.isNotEmpty;

  return SleepSummary(
    asleepMinutes: asleep,
    deepMinutes: hasStages ? minutes(deep) : null,
    remMinutes: hasStages ? minutes(rem) : null,
    lightMinutes: hasStages ? minutes(light) : null,
    awakeMinutes: awake.isNotEmpty || hasStages ? minutes(awake) : null,
    bedtime: everything.isEmpty ? null : everything.first.from,
    wakeTime: everything.isEmpty ? null : everything.last.to,
  );
}
