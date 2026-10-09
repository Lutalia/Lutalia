/// Where a day's health values came from.
enum HealthDataSource {
  appleHealth('apple_health'),
  healthConnect('health_connect');

  const HealthDataSource(this.id);

  final String id;

  static HealthDataSource? fromId(Object? id) {
    for (final HealthDataSource s in values) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// One night of sleep as read from Apple Health / Health Connect.
///
/// Stage minutes are null when the source recorded only a total (common for
/// phone-only tracking or Samsung Health sessions without stages) — that is
/// "unknown", not zero.
class SleepSummary {
  const SleepSummary({
    required this.asleepMinutes,
    this.deepMinutes,
    this.remMinutes,
    this.lightMinutes,
    this.awakeMinutes,
    this.bedtime,
    this.wakeTime,
  });

  final int asleepMinutes;
  final int? deepMinutes;
  final int? remMinutes;
  final int? lightMinutes;
  final int? awakeMinutes;
  final DateTime? bedtime;
  final DateTime? wakeTime;

  bool get hasStages =>
      deepMinutes != null || remMinutes != null || lightMinutes != null;

  double get asleepHours => asleepMinutes / 60.0;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'asleepMinutes': asleepMinutes,
    'deepMinutes': deepMinutes,
    'remMinutes': remMinutes,
    'lightMinutes': lightMinutes,
    'awakeMinutes': awakeMinutes,
    'bedtime': bedtime?.toIso8601String(),
    'wakeTime': wakeTime?.toIso8601String(),
  };

  static SleepSummary? fromJson(Object? json) {
    if (json is! Map) return null;
    final int? asleep = _asInt(json['asleepMinutes']);
    if (asleep == null) return null;
    return SleepSummary(
      asleepMinutes: asleep,
      deepMinutes: _asInt(json['deepMinutes']),
      remMinutes: _asInt(json['remMinutes']),
      lightMinutes: _asInt(json['lightMinutes']),
      awakeMinutes: _asInt(json['awakeMinutes']),
      bedtime: _asDate(json['bedtime']),
      wakeTime: _asDate(json['wakeTime']),
    );
  }
}

/// Health values stored for one calendar day (`yyyy-MM-dd`).
class HealthDaySummary {
  const HealthDaySummary({
    required this.dateKey,
    required this.source,
    required this.syncedAt,
    this.steps,
    this.sleep,
  });

  final String dateKey;
  final int? steps;
  final SleepSummary? sleep;
  final HealthDataSource source;
  final DateTime syncedAt;

  bool get isEmpty => steps == null && sleep == null;

  /// Newer non-null values win, so a steps-only sync never wipes stored sleep.
  HealthDaySummary mergedWith(HealthDaySummary newer) => HealthDaySummary(
    dateKey: dateKey,
    steps: newer.steps ?? steps,
    sleep: newer.sleep ?? sleep,
    source: newer.source,
    syncedAt: newer.syncedAt,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'dateKey': dateKey,
    'steps': steps,
    'sleep': sleep?.toJson(),
    'source': source.id,
    'syncedAt': syncedAt.toIso8601String(),
  };

  static HealthDaySummary? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? key = json['dateKey'];
    final HealthDataSource? source = HealthDataSource.fromId(json['source']);
    if (key is! String || source == null) return null;
    return HealthDaySummary(
      dateKey: key,
      steps: _asInt(json['steps']),
      sleep: SleepSummary.fromJson(json['sleep']),
      source: source,
      syncedAt: _asDate(json['syncedAt']) ?? DateTime.now(),
    );
  }

  static String keyFor(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

int? _asInt(Object? value) => value is num ? value.round() : null;

DateTime? _asDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
