/// Weekday filter options — [DateTime.weekday] values (1 = Monday … 7 = Sunday).
class WtvaWeekdays {
  WtvaWeekdays._();

  static const all = [
    _Day(id: 1, label: 'Monday', shortLabel: 'Mon'),
    _Day(id: 2, label: 'Tuesday', shortLabel: 'Tue'),
    _Day(id: 3, label: 'Wednesday', shortLabel: 'Wed'),
    _Day(id: 4, label: 'Thursday', shortLabel: 'Thu'),
    _Day(id: 5, label: 'Friday', shortLabel: 'Fri'),
    _Day(id: 6, label: 'Saturday', shortLabel: 'Sat'),
    _Day(id: 7, label: 'Sunday', shortLabel: 'Sun'),
  ];

  static String labelFor(int weekday) {
    return all.firstWhere((d) => d.id == weekday, orElse: () => all.first).label;
  }
}

class _Day {
  const _Day({required this.id, required this.label, required this.shortLabel});

  final int id;
  final String label;
  final String shortLabel;
}
