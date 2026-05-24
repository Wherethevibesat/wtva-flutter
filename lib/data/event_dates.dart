/// Local calendar dates for event filtering (`YYYY-MM-DD`).
class EventDates {
  EventDates._();

  static String toIsoDate(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime parseIsoDate(String iso) {
    final parts = iso.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  static bool startsOnLocalDate(DateTime startsAt, String isoDate) {
    return toIsoDate(startsAt.toLocal()) == isoDate;
  }

  static String shortLabel(String isoDate) {
    final date = parseIsoDate(isoDate);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
