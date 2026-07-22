import 'package:intl/intl.dart';

import '../models/venue.dart';
import '../services/events_repository.dart';

class TonightEventItem {
  const TonightEventItem({
    required this.eventId,
    required this.title,
    required this.imageUrl,
    required this.whenLabel,
    required this.venueLabel,
    required this.metaLabel,
  });

  final String eventId;
  final String title;
  final String imageUrl;
  final String whenLabel;
  final String venueLabel;
  final String metaLabel;
}

class TonightTrendingItem {
  const TonightTrendingItem({
    required this.venueId,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.badge,
    required this.rating,
    required this.goingLabel,
    required this.tag,
    required this.etaLabel,
  });

  final String venueId;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String badge;
  final double rating;
  final String goingLabel;
  final String tag;
  final String etaLabel;
}

class TonightHappyHourItem {
  const TonightHappyHourItem({
    required this.venueName,
    required this.deal,
    required this.imageUrl,
    required this.endsInLabel,
    required this.distanceLabel,
    this.venueId,
  });

  final String venueName;
  final String deal;
  final String imageUrl;
  final String endsInLabel;
  final String distanceLabel;
  final String? venueId;
}

class TonightVibeItem {
  const TonightVibeItem({
    required this.label,
    required this.countLabel,
    required this.query,
  });

  final String label;
  final String countLabel;
  final String query;
}

class TonightFeed {
  TonightFeed._();

  static List<TonightEventItem> featuredEvents(List<WtvaEventRecord> events) {
    return events.take(6).map(_toEventItem).toList();
  }

  static List<TonightEventItem> upcomingEvents(List<WtvaEventRecord> events) {
    if (events.isEmpty) return const [];
    final slice = events.length > 6 ? events.skip(2).take(8).toList() : events;
    return slice.map(_toEventItem).toList();
  }

  static TonightEventItem _toEventItem(WtvaEventRecord e) {
    final venue = e.venueName?.trim();
    final hood = e.neighborhood?.trim();
    final venueLabel = [
      if (venue != null && venue.isNotEmpty) venue,
      if (hood != null && hood.isNotEmpty) hood,
    ].join(' · ');
    return TonightEventItem(
      eventId: e.id,
      title: e.title,
      imageUrl: e.imageUrl ??
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=80',
      whenLabel: _whenLabel(e.startsAt),
      venueLabel: venueLabel.isEmpty ? e.eventType : venueLabel,
      metaLabel: '${e.eventType} · ${_timeLabel(e.startsAt, e.endsAt)}',
    );
  }

  static String _whenLabel(DateTime startsAt) {
    final local = startsAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return 'TONIGHT';
    if (day == today.add(const Duration(days: 1))) return 'TOMORROW';
    return DateFormat('EEE, MMM d').format(local).toUpperCase();
  }

  static String _timeLabel(DateTime startsAt, DateTime? endsAt) {
    final start = DateFormat('h:mm a').format(startsAt.toLocal());
    if (endsAt == null) return start;
    final end = DateFormat('h:mm a').format(endsAt.toLocal());
    return '$start – $end';
  }

  static List<TonightTrendingItem> trendingFrom({
    required List<WtvaEventRecord> events,
    required List<Venue> venues,
  }) {
    final pool = venues;
    if (pool.isEmpty) return const [];

    if (events.isNotEmpty) {
      final slice = events.take(8).toList();
      return [
        for (var i = 0; i < slice.length; i++)
          TonightTrendingItem(
            venueId: pool[i % pool.length].id,
            title: slice[i].venueName ?? slice[i].title,
            subtitle: slice[i].title,
            imageUrl: slice[i].imageUrl ?? pool[i % pool.length].imageUrl,
            badge: slice[i].eventType,
            rating: pool[i % pool.length].rating,
            goingLabel: '',
            tag: slice[i].eventType,
            etaLabel: _etaFromMiles(pool[i % pool.length].distanceMiles),
          ),
      ];
    }

    return [
      for (final v in pool.take(6))
        TonightTrendingItem(
          venueId: v.id,
          title: v.name,
          subtitle: '',
          imageUrl: v.imageUrl,
          badge: '',
          rating: v.rating,
          goingLabel: '',
          tag: '',
          etaLabel: _etaFromMiles(v.distanceMiles),
        ),
    ];
  }

  static List<TonightHappyHourItem> happyHoursFrom({
    required List<WtvaEventRecord> events,
    required List<Venue> venues,
  }) {
    final pool = venues;
    final happy = events
        .where((e) => e.eventType.toLowerCase().contains('happy'))
        .take(6)
        .toList();

    if (happy.isEmpty) return const [];

    return [
      for (var i = 0; i < happy.length; i++)
        TonightHappyHourItem(
          venueName: happy[i].venueName ?? happy[i].title,
          deal: happy[i].title,
          imageUrl: happy[i].imageUrl ??
              (pool.isNotEmpty ? pool[i % pool.length].imageUrl : ''),
          endsInLabel: _whenLabel(happy[i].startsAt),
          distanceLabel: pool.isNotEmpty
              ? '${pool[i % pool.length].distanceMiles.toStringAsFixed(1)} mi'
              : '',
          venueId: pool.isNotEmpty ? pool[i % pool.length].id : null,
        ),
    ];
  }

  static List<TonightVibeItem> vibes({required int eventCount}) {
    return const [
      TonightVibeItem(label: 'Afrobeats', countLabel: '', query: 'Afrobeats'),
      TonightVibeItem(label: 'Rooftops', countLabel: '', query: 'Rooftop'),
      TonightVibeItem(label: 'Day Parties', countLabel: '', query: 'Day Party'),
      TonightVibeItem(label: 'Brunch', countLabel: '', query: 'Brunch'),
      TonightVibeItem(label: 'VIP', countLabel: '', query: 'VIP'),
      TonightVibeItem(label: 'After Hours', countLabel: '', query: 'After Hours'),
    ];
  }

  static String _etaFromMiles(double miles) {
    final mins = (miles * 4 + 8).round().clamp(8, 45);
    return '$mins min';
  }

  static String greetingFor(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'there';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }
}
