import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/health_day_summary.dart';
import 'health_permission_bridge.dart';
import 'health_service.dart';

/// Result of a sync, precise enough for the UI to say what actually happened.
enum HealthSyncOutcome {
  /// Access granted and today's values were read.
  connected,

  /// Steps or sleep allowed, the other refused (Health Connect only).
  partial,

  /// Access looks granted but the platform holds no records for today —
  /// usually Samsung Health / Google Fit not syncing into Health Connect, or
  /// sleep/steps switched off under iOS Settings › Health.
  noData,

  denied,

  /// Android without Health Connect (normal on Android 13 and lower).
  notInstalled,

  /// Health Connect present but unusable until updated.
  needsUpdate,

  /// Web / desktop.
  unsupported,
}

class HealthSyncResult {
  const HealthSyncResult(this.outcome, [this.today]);

  final HealthSyncOutcome outcome;

  /// Today's stored values after the sync (may come from cache when the
  /// platform returned nothing new).
  final HealthDaySummary? today;

  bool get isSuccess =>
      outcome == HealthSyncOutcome.connected ||
      outcome == HealthSyncOutcome.partial;
}

/// Pulls steps and sleep from Apple Health / Health Connect and stores one
/// [HealthDaySummary] per day: locally (SharedPreferences, works offline) and
/// in Firestore at `users/{uid}/health_days/{yyyy-MM-dd}` when signed in.
///
/// * [connect] is user-initiated and may show the system permission sheet.
/// * [refreshToday] / [loadDailySteps] never prompt — safe on screen open.
///
/// Per-day document ids keep re-syncs idempotent: a repeat pull overwrites
/// the day instead of duplicating it.
class HealthSyncService {
  const HealthSyncService._();

  static const String _connectedKey = 'lutalia_health_connected';
  static const String _iosAuthorizedKey = 'lutalia_health_ios_authorized';
  static String _dayKey(String dateKey) => 'lutalia_health_day_$dateKey';

  static HealthService get _platform => HealthService.instance;

  static Future<HealthSyncResult>? _inFlight;

  /// True once the user connected successfully. Background refreshes only run
  /// for connected users so a screen open never surprises with a prompt.
  static Future<bool> isConnected() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_connectedKey) ?? false;
  }

  /// User-initiated: availability → permission sheet → read → store.
  /// Concurrent taps share one run.
  static Future<HealthSyncResult> connect() =>
      _inFlight ??= _connect().whenComplete(() => _inFlight = null);

  static Future<HealthSyncResult> _connect() async {
    if (!HealthService.isSupportedPlatform) {
      return const HealthSyncResult(HealthSyncOutcome.unsupported);
    }
    final HealthSyncOutcome? blocked = await _availabilityBlocker();
    if (blocked != null) return HealthSyncResult(blocked);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool sheetCompleted = await _platform.requestAuthorization();
    if (sheetCompleted && _platform.source == HealthDataSource.appleHealth) {
      await prefs.setBool(_iosAuthorizedKey, true);
    }
    final HealthAccess access = await _platform.access(
      iosAuthorized: prefs.getBool(_iosAuthorizedKey) ?? false,
    );

    // An actual read is the only trustworthy proof of access; grant
    // bookkeeping can lag behind a just-completed sheet on some phones.
    final HealthDaySummary? fresh = await _readToday();
    final HealthDaySummary? stored = fresh == null
        ? await cachedDay(DateTime.now())
        : await _save(fresh);

    final HealthSyncOutcome outcome;
    if (fresh != null) {
      outcome = access.isPartial
          ? HealthSyncOutcome.partial
          : HealthSyncOutcome.connected;
    } else if (access.isPartial) {
      outcome = HealthSyncOutcome.partial;
    } else if (access.hasAny) {
      outcome = HealthSyncOutcome.noData;
    } else {
      outcome = HealthSyncOutcome.denied;
    }

    if (outcome != HealthSyncOutcome.denied) {
      await prefs.setBool(_connectedKey, true);
    }
    HealthPermissionBridge.log(
      'connect outcome=$outcome steps=${access.steps} sleep=${access.sleep} '
      'fresh=${fresh != null}',
    );
    return HealthSyncResult(outcome, stored);
  }

  /// Silent refresh for an already-connected user. Never prompts. Returns
  /// the stored day (fresh if the platform answered, cached otherwise).
  static Future<HealthDaySummary?> refreshToday() async {
    if (!HealthService.isSupportedPlatform || !await isConnected()) {
      return cachedDay(DateTime.now());
    }
    if (await _availabilityBlocker() != null) return cachedDay(DateTime.now());
    final HealthDaySummary? fresh = await _readToday();
    if (fresh == null) return cachedDay(DateTime.now());
    return _save(fresh);
  }

  /// Daily step totals for the last [days] days (oldest first), read from
  /// the platform and stored per day. Falls back to stored values for days
  /// the platform could not answer. Never prompts.
  static Future<List<({DateTime day, int? steps})>> loadDailySteps(
    int days,
  ) async {
    final List<({DateTime day, int? steps})> platform =
        HealthService.isSupportedPlatform &&
            await isConnected() &&
            await _availabilityBlocker() == null
        ? await _platform.readDailySteps(days)
        : const <({DateTime day, int? steps})>[];

    final DateTime now = DateTime.now();
    final List<({DateTime day, int? steps})> out =
        <({DateTime day, int? steps})>[];
    for (int i = days - 1; i >= 0; i--) {
      final DateTime day = DateTime(now.year, now.month, now.day - i);
      final int index = days - 1 - i;
      final int? read = index < platform.length ? platform[index].steps : null;
      if (read != null) {
        await _save(
          HealthDaySummary(
            dateKey: HealthDaySummary.keyFor(day),
            steps: read,
            source: _platform.source,
            syncedAt: now,
          ),
        );
        out.add((day: day, steps: read));
      } else {
        out.add((day: day, steps: (await cachedDay(day))?.steps));
      }
    }
    return out;
  }

  static Future<HealthDaySummary?> cachedDay(DateTime day) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_dayKey(HealthDaySummary.keyFor(day)));
    if (raw == null) return null;
    try {
      return HealthDaySummary.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> openPermissionSettings() =>
      _platform.openPermissionSettings();

  static Future<bool> installHealthConnect() =>
      _platform.installHealthConnect();

  static Future<HealthSyncOutcome?> _availabilityBlocker() async {
    switch (await _platform.availability()) {
      case HealthAvailability.notInstalled:
        return HealthSyncOutcome.notInstalled;
      case HealthAvailability.needsUpdate:
        return HealthSyncOutcome.needsUpdate;
      case HealthAvailability.available:
      case HealthAvailability.unknown:
        return null;
    }
  }

  static Future<HealthDaySummary?> _readToday() async {
    final DateTime now = DateTime.now();
    final DateTime midnight = DateTime(now.year, now.month, now.day);
    final List<Object?> reads = await Future.wait<Object?>(<Future<Object?>>[
      _platform.readSteps(midnight, now),
      _platform.readSleep(now),
    ]);
    final HealthDaySummary summary = HealthDaySummary(
      dateKey: HealthDaySummary.keyFor(now),
      steps: reads[0] as int?,
      sleep: reads[1] as SleepSummary?,
      source: _platform.source,
      syncedAt: now,
    );
    return summary.isEmpty ? null : summary;
  }

  /// Merges into the stored day (so a steps-only write keeps sleep), saves
  /// locally, then mirrors to Firestore. Firestore failures never fail the
  /// sync — the SDK queues writes offline and the local copy stays valid.
  static Future<HealthDaySummary> _save(HealthDaySummary incoming) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = _dayKey(incoming.dateKey);
    HealthDaySummary merged = incoming;
    bool changed = true;
    final String? raw = prefs.getString(key);
    if (raw != null) {
      try {
        final HealthDaySummary? existing = HealthDaySummary.fromJson(
          jsonDecode(raw),
        );
        if (existing != null) {
          merged = existing.mergedWith(incoming);
          changed = !_sameValues(existing, merged);
        }
      } catch (_) {
        // Corrupt cache entry: overwrite it.
      }
    }
    await prefs.setString(key, jsonEncode(merged.toJson()));

    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && changed) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('health_days')
          .doc(merged.dateKey)
          .set(merged.toJson(), SetOptions(merge: true))
          .catchError((Object e) {
            HealthPermissionBridge.log('firestore save failed: $e');
          });
    }
    return merged;
  }

  /// Ignores `syncedAt`, so repeat refreshes don't churn storage or Firestore.
  static bool _sameValues(HealthDaySummary a, HealthDaySummary b) =>
      a.steps == b.steps &&
      a.source == b.source &&
      jsonEncode(a.sleep?.toJson()) == jsonEncode(b.sleep?.toJson());
}
