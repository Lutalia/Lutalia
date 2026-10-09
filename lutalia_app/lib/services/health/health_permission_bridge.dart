import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';

/// Whether the Health Connect provider is usable on this phone.
enum HealthAvailability {
  available,

  /// Provider package missing — normal on Android 13 and lower, where Health
  /// Connect is a Play Store app rather than part of the OS.
  notInstalled,

  /// Package present but the SDK refuses to work (usually Play services or
  /// Health Connect itself needs an update).
  needsUpdate,

  /// Could not be determined (iOS, web, desktop, or a channel failure).
  unknown,
}

/// One Health Connect permission and the plugin data types it unlocks.
@immutable
class HealthConnectPermission {
  const HealthConnectPermission(this.permission, this.types);

  final String permission;
  final List<HealthDataType> types;
}

/// Android-only channel into `MainActivity` for the Health Connect permission
/// sheet, grant lookup, availability and settings.
///
/// The `health` plugin's own launcher is often null when a request arrives
/// and then reports "denied" without showing anything, so the request goes
/// through a contract registered natively in `onCreate`.
class HealthPermissionBridge {
  const HealthPermissionBridge._();

  static const MethodChannel _channel = MethodChannel(
    'com.example.lutalia_app/health_permissions',
  );

  /// Exactly what Lutalia reads. Every entry must be declared in
  /// AndroidManifest.xml — no more, no less. All sleep stages are covered by
  /// the single READ_SLEEP permission.
  static const List<HealthConnectPermission> permissions =
      <HealthConnectPermission>[
        HealthConnectPermission(
          'android.permission.health.READ_STEPS',
          <HealthDataType>[HealthDataType.STEPS],
        ),
        HealthConnectPermission(
          'android.permission.health.READ_SLEEP',
          <HealthDataType>[
            HealthDataType.SLEEP_SESSION,
            HealthDataType.SLEEP_ASLEEP,
            HealthDataType.SLEEP_LIGHT,
            HealthDataType.SLEEP_DEEP,
            HealthDataType.SLEEP_REM,
            HealthDataType.SLEEP_AWAKE,
            HealthDataType.SLEEP_AWAKE_IN_BED,
          ],
        ),
      ];

  static const String stepsPermission = 'android.permission.health.READ_STEPS';
  static const String sleepPermission = 'android.permission.health.READ_SLEEP';

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<HealthAvailability> availability() async {
    if (!isSupported) return HealthAvailability.unknown;
    try {
      final Object? reply = await _channel.invokeMethod<Object?>(
        'getAvailability',
      );
      if (reply is! Map) return HealthAvailability.unknown;
      final bool installed = reply['providerInstalled'] == true;
      final Object? rawStatus = reply['sdkStatus'];
      final int status = rawStatus is int ? rawStatus : -1;
      // HealthConnectClient.SDK_AVAILABLE == 3.
      final HealthAvailability resolved = status == 3
          ? HealthAvailability.available
          : installed
          ? HealthAvailability.needsUpdate
          : HealthAvailability.notInstalled;
      log('availability=$resolved installed=$installed sdkStatus=$status');
      return resolved;
    } on PlatformException catch (e) {
      log('availability failed: ${e.code} ${e.message}');
      return HealthAvailability.unknown;
    } on MissingPluginException {
      return HealthAvailability.unknown;
    }
  }

  /// Shows the Health Connect sheet for [requested] permission strings and
  /// returns the full set granted afterwards, or null when no sheet could be
  /// shown (the caller then falls back to the plugin).
  static Future<Set<String>?> request(Set<String> requested) async {
    if (!isSupported || requested.isEmpty) return null;
    try {
      final Object? reply = await _channel.invokeMethod<Object?>(
        'requestAuthorization',
        <String, dynamic>{'permissions': requested.toList()},
      );
      final Set<String> granted = _stringsOf(reply);
      log('request asked=${requested.join(",")} granted=${granted.join(",")}');
      return granted;
    } on PlatformException catch (e) {
      log('request failed: ${e.code} ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Permissions Health Connect reports as granted, or null when the read
  /// itself failed. Null ("could not ask") and empty ("nothing allowed") mean
  /// different things and must never be collapsed. Never prompts.
  static Future<Set<String>?> granted() async {
    if (!isSupported) return null;
    try {
      final Object? reply = await _channel.invokeMethod<Object?>(
        'getGrantedPermissions',
      );
      if (reply is! Map || reply['ok'] != true) {
        log('granted read failed: $reply');
        return null;
      }
      return _stringsOf(reply['granted']);
    } on PlatformException catch (e) {
      log('granted read failed: ${e.code} ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<bool> openSettings() => _invokeBool('openPermissions');

  static Future<bool> installProvider() => _invokeBool('installProvider');

  static Future<bool> _invokeBool(String method) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<Object?>(method) == true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Set<String> _stringsOf(Object? value) {
    if (value is! List) return <String>{};
    return <String>{
      for (final Object? item in value)
        if (item is String) item,
    };
  }

  /// Debug builds only. Printed to the `flutter run` console (filter by
  /// `lutalia.health`) and mirrored to DevTools.
  static void log(String message) {
    if (!kDebugMode) return;
    debugPrint('[lutalia.health] $message');
    developer.log(message, name: 'lutalia.health');
  }
}
