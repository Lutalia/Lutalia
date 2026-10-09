import 'package:flutter/foundation.dart';

import 'health_sync_service.dart';

/// User-facing copy for the Apple Health / Health Connect integration.
class HealthTexts {
  const HealthTexts._();

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static String get platformName => _isIOS ? 'Apple Health' : 'Health Connect';

  static const String syncButton =
      'APPLE HEALTH / HEALTH CONNECT SYNCHRONISIEREN';
  static const String syncing = 'SYNCHRONISIERE …';
  static const String noStages =
      'Deine Quelle liefert keine Schlafphasen – nur die Gesamtdauer.';
  static const String noData = 'Keine Daten';

  static String get noSleepLastNight => _isIOS
      ? 'Für letzte Nacht sind keine Schlafdaten in Apple Health vorhanden. '
            'Die Werte unten sind manuell.'
      : 'Für letzte Nacht sind keine Schlafdaten in Health Connect vorhanden '
            '(z. B. Samsung Health › Einstellungen › Health Connect › Schlaf). '
            'Die Werte unten sind manuell.';

  static String lastSynced(DateTime at) =>
      'Zuletzt synchronisiert: ${_two(at.hour)}:${_two(at.minute)} Uhr · '
      '$platformName';

  static String clock(DateTime at) => '${_two(at.hour)}:${_two(at.minute)} Uhr';

  static String message(HealthSyncOutcome outcome) => switch (outcome) {
    HealthSyncOutcome.connected => '$platformName erfolgreich synchronisiert.',
    HealthSyncOutcome.partial =>
      'Nur teilweise freigegeben. Erlaube Schritte und Schlaf in '
          '$platformName, um alle Werte zu sehen.',
    HealthSyncOutcome.noData =>
      _isIOS
          ? 'Verbunden – aber Apple Health enthält noch keine Daten für heute. '
                'Prüfe unter Einstellungen › Health › Datenzugriff › Lutalia, '
                'ob Schritte und Schlaf erlaubt sind.'
          : 'Verbunden – aber Health Connect enthält noch keine Daten für heute. '
                'Aktiviere in Samsung Health / Google Fit die Synchronisierung '
                'mit Health Connect.',
    HealthSyncOutcome.denied =>
      'Kein Zugriff auf $platformName. Bitte erlaube Schritte und Schlaf in '
          'den Einstellungen.',
    HealthSyncOutcome.notInstalled =>
      'Health Connect ist auf diesem Gerät nicht installiert.',
    HealthSyncOutcome.needsUpdate =>
      'Health Connect muss aktualisiert werden, bevor Lutalia Daten lesen kann.',
    HealthSyncOutcome.unsupported =>
      'Gesundheitsdaten sind nur auf iPhone und Android verfügbar.',
  };

  /// Label for the snackbar action that repairs the outcome, if any.
  static String? actionLabel(HealthSyncOutcome outcome) => switch (outcome) {
    HealthSyncOutcome.partial ||
    HealthSyncOutcome.denied ||
    HealthSyncOutcome.noData => 'EINSTELLUNGEN',
    HealthSyncOutcome.notInstalled => 'INSTALLIEREN',
    HealthSyncOutcome.needsUpdate => 'AKTUALISIEREN',
    _ => null,
  };

  static String _two(int v) => v.toString().padLeft(2, '0');
}
