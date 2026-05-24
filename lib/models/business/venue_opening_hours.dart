const weekdayKeys = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

const weekdayLabels = {
  'monday': 'Monday',
  'tuesday': 'Tuesday',
  'wednesday': 'Wednesday',
  'thursday': 'Thursday',
  'friday': 'Friday',
  'saturday': 'Saturday',
  'sunday': 'Sunday',
};

class VenueDayHours {
  final bool closed;
  final String? open;
  final String? close;

  const VenueDayHours({
    this.closed = true,
    this.open,
    this.close,
  });

  VenueDayHours copyWith({
    bool? closed,
    String? open,
    String? close,
  }) {
    return VenueDayHours(
      closed: closed ?? this.closed,
      open: open ?? this.open,
      close: close ?? this.close,
    );
  }

  Map<String, dynamic> toJson() => {
        'closed': closed,
        'open': open,
        'close': close,
      };

  factory VenueDayHours.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VenueDayHours();
    return VenueDayHours(
      closed: json['closed'] as bool? ?? true,
      open: json['open'] as String?,
      close: json['close'] as String?,
    );
  }
}

class VenueOpeningHours {
  final Map<String, VenueDayHours> days;

  VenueOpeningHours(Map<String, VenueDayHours> days) : days = Map.unmodifiable(days);

  factory VenueOpeningHours.defaults() {
    const closed = VenueDayHours(closed: true);
    const weekend = VenueDayHours(closed: false, open: '21:00', close: '02:00');
    return VenueOpeningHours({
      'monday': closed,
      'tuesday': closed,
      'wednesday': closed,
      'thursday': weekend,
      'friday': weekend,
      'saturday': weekend,
      'sunday': const VenueDayHours(closed: false, open: '20:00', close: '00:00'),
    });
  }

  VenueDayHours day(String key) => days[key] ?? const VenueDayHours();

  VenueOpeningHours copyDay(String key, VenueDayHours value) {
    final next = Map<String, VenueDayHours>.from(days);
    next[key] = value;
    return VenueOpeningHours(next);
  }

  Map<String, dynamic> toJson() {
    return {for (final key in weekdayKeys) key: days[key]?.toJson() ?? const VenueDayHours().toJson()};
  }

  factory VenueOpeningHours.fromJson(dynamic json) {
    final base = VenueOpeningHours.defaults();
    if (json is! Map) return base;
    final next = Map<String, VenueDayHours>.from(base.days);
    for (final key in weekdayKeys) {
      final raw = json[key];
      if (raw is Map) {
        next[key] = VenueDayHours.fromJson(Map<String, dynamic>.from(raw));
      }
    }
    return VenueOpeningHours(next);
  }

  String formatHoursLabel() {
    final parts = <String>[];
    for (final key in weekdayKeys) {
      final slot = day(key);
      if (slot.closed || slot.open == null || slot.close == null) continue;
      final label = weekdayLabels[key]!.substring(0, 3);
      parts.add('$label ${_format12(slot.open!)}–${_format12(slot.close!)}');
    }
    return parts.isEmpty ? 'Closed' : parts.join(' · ');
  }

  static String _format12(String time) {
    final pieces = time.split(':');
    final h = int.tryParse(pieces.first) ?? 0;
    final m = pieces.length > 1 ? int.tryParse(pieces[1]) ?? 0 : 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    if (m > 0) {
      return '$hour12:${m.toString().padLeft(2, '0')} $period';
    }
    return '$hour12 $period';
  }
}
