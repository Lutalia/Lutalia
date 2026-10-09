/// Each day owns the sleep from 18:00 the previous evening to 18:00 that day,
/// so last night is attributed to today and consecutive days never overlap.
const int sleepDayBoundaryHour = 18;

typedef TimeInterval = ({DateTime from, DateTime to});

/// Read window for the night that belongs to [day]. For today the end is
/// capped at [now] so the query never asks about the future. Built from
/// calendar fields so a DST change keeps the local 18:00 anchors.
({DateTime start, DateTime end}) sleepReadWindow(
  DateTime day, {
  DateTime? now,
}) {
  final DateTime start = DateTime(
    day.year,
    day.month,
    day.day - 1,
    sleepDayBoundaryHour,
  );
  final DateTime boundary = DateTime(
    day.year,
    day.month,
    day.day,
    sleepDayBoundaryHour,
  );
  final DateTime current = now ?? DateTime.now();
  return (start: start, end: current.isBefore(boundary) ? current : boundary);
}

/// Intervals clipped to `[start, end]`, sorted and with overlaps merged. A
/// phone and a watch recording the same night must not double the total.
List<TimeInterval> mergeIntervals(
  Iterable<TimeInterval> intervals, {
  required DateTime start,
  required DateTime end,
}) {
  final List<TimeInterval> clipped = <TimeInterval>[];
  for (final TimeInterval i in intervals) {
    final DateTime from = i.from.isBefore(start) ? start : i.from;
    final DateTime to = i.to.isAfter(end) ? end : i.to;
    if (to.isAfter(from)) clipped.add((from: from, to: to));
  }
  if (clipped.isEmpty) return clipped;
  clipped.sort((TimeInterval a, TimeInterval b) => a.from.compareTo(b.from));

  final List<TimeInterval> merged = <TimeInterval>[clipped.first];
  for (final TimeInterval i in clipped.skip(1)) {
    final TimeInterval last = merged.last;
    if (i.from.isAfter(last.to)) {
      merged.add(i);
    } else if (i.to.isAfter(last.to)) {
      merged[merged.length - 1] = (from: last.from, to: i.to);
    }
  }
  return merged;
}

/// Minutes covered by [intervals] inside `[start, end]`, overlap counted once.
int mergedMinutes(
  Iterable<TimeInterval> intervals, {
  required DateTime start,
  required DateTime end,
}) {
  int totalMs = 0;
  for (final TimeInterval i in mergeIntervals(
    intervals,
    start: start,
    end: end,
  )) {
    totalMs += i.to.difference(i.from).inMilliseconds;
  }
  return (totalMs / Duration.millisecondsPerMinute).round();
}
