import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:lutalia/models/health_day_summary.dart';
import 'package:lutalia/services/health/health_service.dart';
import 'package:lutalia/utils/sleep_window.dart';

void main() {
  final DateTime start = DateTime(2026, 10, 7, 18);
  final DateTime end = DateTime(2026, 10, 8, 18);
  TimeInterval at(int fromH, int fromM, int toH, int toM) {
    DateTime t(int h, int m) =>
        h >= 18 ? DateTime(2026, 10, 7, h, m) : DateTime(2026, 10, 8, h, m);
    return (from: t(fromH, fromM), to: t(toH, toM));
  }

  group('sleepReadWindow', () {
    test('runs 18:00 yesterday to now before the boundary', () {
      final DateTime now = DateTime(2026, 10, 8, 9, 30);
      final w = sleepReadWindow(now, now: now);
      expect(w.start, DateTime(2026, 10, 7, 18));
      expect(w.end, now);
    });

    test('stops at 18:00 for past days', () {
      final w = sleepReadWindow(
        DateTime(2026, 10, 5),
        now: DateTime(2026, 10, 8, 9),
      );
      expect(w.start, DateTime(2026, 10, 4, 18));
      expect(w.end, DateTime(2026, 10, 5, 18));
    });
  });

  group('mergedMinutes', () {
    test('counts phone + watch overlap once', () {
      final int minutes = mergedMinutes(
        <TimeInterval>[at(23, 0, 7, 0), at(23, 30, 6, 30)],
        start: start,
        end: end,
      );
      expect(minutes, 8 * 60);
    });

    test('clips to the window', () {
      final int minutes = mergedMinutes(
        <TimeInterval>[
          (from: DateTime(2026, 10, 7, 17), to: DateTime(2026, 10, 7, 19)),
        ],
        start: start,
        end: end,
      );
      expect(minutes, 60);
    });
  });

  group('summarizeSleep', () {
    test('uses stages when present (iOS / staged Health Connect)', () {
      final SleepSummary? s = summarizeSleep(
        <HealthDataType, List<TimeInterval>>{
          HealthDataType.SLEEP_LIGHT: <TimeInterval>[
            at(23, 0, 1, 0),
            at(3, 0, 5, 0),
          ],
          HealthDataType.SLEEP_DEEP: <TimeInterval>[at(1, 0, 2, 30)],
          HealthDataType.SLEEP_REM: <TimeInterval>[at(2, 30, 3, 0)],
          HealthDataType.SLEEP_AWAKE: <TimeInterval>[at(5, 0, 5, 15)],
        },
        start: start,
        end: end,
      );
      expect(s, isNotNull);
      expect(s!.asleepMinutes, 6 * 60);
      expect(s.lightMinutes, 4 * 60);
      expect(s.deepMinutes, 90);
      expect(s.remMinutes, 30);
      expect(s.awakeMinutes, 15);
      expect(s.hasStages, isTrue);
      expect(s.bedtime, DateTime(2026, 10, 7, 23));
      expect(s.wakeTime, DateTime(2026, 10, 8, 5, 15));
    });

    test('Health Connect session without stages: session minus awake', () {
      final SleepSummary? s = summarizeSleep(
        <HealthDataType, List<TimeInterval>>{
          HealthDataType.SLEEP_SESSION: <TimeInterval>[at(22, 30, 6, 30)],
          HealthDataType.SLEEP_AWAKE: <TimeInterval>[at(3, 0, 3, 20)],
        },
        start: start,
        end: end,
      );
      expect(s!.asleepMinutes, 8 * 60 - 20);
      expect(s.hasStages, isFalse);
      expect(s.deepMinutes, isNull);
      expect(s.awakeMinutes, 20);
    });

    test('iPhone without watch: in-bed time as fallback', () {
      final SleepSummary? s = summarizeSleep(
        <HealthDataType, List<TimeInterval>>{
          HealthDataType.SLEEP_IN_BED: <TimeInterval>[at(23, 0, 6, 0)],
        },
        start: start,
        end: end,
      );
      expect(s!.asleepMinutes, 7 * 60);
      expect(s.awakeMinutes, isNull);
    });

    test('nothing recorded returns null', () {
      expect(
        summarizeSleep(
          <HealthDataType, List<TimeInterval>>{},
          start: start,
          end: end,
        ),
        isNull,
      );
    });
  });

  test('HealthDaySummary merge keeps stored sleep on a steps-only write', () {
    final HealthDaySummary stored = HealthDaySummary(
      dateKey: '2026-10-08',
      steps: 1000,
      sleep: const SleepSummary(asleepMinutes: 420),
      source: HealthDataSource.healthConnect,
      syncedAt: DateTime(2026, 10, 8, 8),
    );
    final HealthDaySummary merged = stored.mergedWith(
      HealthDaySummary(
        dateKey: '2026-10-08',
        steps: 4200,
        source: HealthDataSource.healthConnect,
        syncedAt: DateTime(2026, 10, 8, 12),
      ),
    );
    expect(merged.steps, 4200);
    expect(merged.sleep?.asleepMinutes, 420);

    final HealthDaySummary? roundTrip = HealthDaySummary.fromJson(
      merged.toJson(),
    );
    expect(roundTrip?.steps, 4200);
    expect(roundTrip?.sleep?.asleepMinutes, 420);
  });
}
