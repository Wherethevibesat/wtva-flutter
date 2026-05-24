class EventRecurrenceInput {
  const EventRecurrenceInput({
    this.enabled = false,
    this.byWeekday = const [],
    this.untilDate = '',
    this.intervalWeeks = 1,
  });

  final bool enabled;
  final List<int> byWeekday;
  final String untilDate;
  final int intervalWeeks;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'by_weekday': byWeekday,
        'until_date': untilDate,
        'interval_weeks': intervalWeeks,
      };
}

class EventOccurrence {
  const EventOccurrence({required this.startsAt, this.endsAt});
  final DateTime startsAt;
  final DateTime? endsAt;
}

const weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const maxOccurrences = 104;

String _isoDate(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

DateTime _shiftToDate(DateTime base, String isoDate) {
  final parts = isoDate.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2], base.hour, base.minute);
}

List<EventOccurrence> buildEventOccurrences({
  required DateTime startsAt,
  DateTime? endsAt,
  List<DateTime> additionalDates = const [],
  EventRecurrenceInput? recurrence,
}) {
  if (endsAt != null && !endsAt.isAfter(startsAt)) {
    throw StateError('End date/time must be after start date/time.');
  }

  final duration = endsAt != null ? endsAt.difference(startsAt) : null;
  final primaryIso = _isoDate(startsAt);
  final map = <String, EventOccurrence>{};

  void add(DateTime start) {
    final end = duration != null ? start.add(duration) : null;
    map[start.toUtc().toIso8601String()] = EventOccurrence(startsAt: start, endsAt: end);
  }

  add(startsAt);

  for (final day in additionalDates) {
    final iso = _isoDate(day);
    if (iso == primaryIso) continue;
    add(_shiftToDate(startsAt, iso));
  }

  if (recurrence?.enabled == true &&
      recurrence!.byWeekday.isNotEmpty &&
      recurrence.untilDate.isNotEmpty) {
    final untilParts = recurrence.untilDate.split('-').map(int.parse).toList();
    final until = DateTime(untilParts[0], untilParts[1], untilParts[2], 23, 59);
    final weekdays = recurrence.byWeekday.toSet();
    var cursor = DateTime(startsAt.year, startsAt.month, startsAt.day);

    while (!cursor.isAfter(until) && map.length < maxOccurrences) {
      if (weekdays.contains(cursor.weekday % 7) && _isoDate(cursor) != primaryIso) {
        add(DateTime(cursor.year, cursor.month, cursor.day, startsAt.hour, startsAt.minute));
      }
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  if (map.length > maxOccurrences) {
    throw StateError('Too many event dates (max $maxOccurrences).');
  }

  final list = map.values.toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return list;
}
