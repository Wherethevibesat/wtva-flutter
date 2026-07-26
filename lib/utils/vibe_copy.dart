import 'package:flutter/material.dart';

/// User-facing Vibe language (DB still uses night_packages).
/// Keep in sync with web-app-customer/src/lib/vibe-copy.ts
class VibeCopy {
  static const curatedTitle = 'Curated Vibes';
  static const curatedSubtitle =
      'Hand-picked by our concierge. Updated every week.';
  static const viewVibe = 'View Vibe';
  static const makeItMine = 'Continue';
  static const buildYourVibe = 'Build Your Vibe';
  static const buildMyVibe = 'Build My Vibe';
  static const buildYourOwn = 'Build Your Own';
  static const surpriseMe = 'Surprise Me';
  static const shuffleAgain = 'Shuffle again';
  static const bookMyVibe = 'Book My Vibe';
  static const myPlans = 'My Plans';
  static const vibesTab = 'Vibes';
  static const yourVibe = 'Your Vibe';
  static const changeStop = 'Change';
  static const continueLabel = 'Continue';
  static const bookedTitle = 'Your vibe is booked';
  static const emptyBrowse =
      'No curated vibes are published yet. Check back soon.';
  static const featuredBadge = 'Trending';
  static const pickYourVibe = 'Pick your vibe';
  static const pickYourVibeSubtitle =
      'Start from an occasion, shuffle a random vibe, or build your own.';
  static const seeAllVibes = 'See all vibes';
  static const softDateNote =
      "We'll confirm this date with each place — subject to availability.";
  static const addExperience = '+ Add experience';
  static const diyVibeSlug = 'build-your-own';
  static const diyVibeId = 'a0000000-0000-4000-8000-0000000000d1';
}

/// Fallback nightlife image when a package has no `image_url`.
const vibePlaceholderImage =
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=80';

String vibeImageUrl(String? url) {
  final t = url?.trim() ?? '';
  return t.isNotEmpty ? t : vibePlaceholderImage;
}

String slotTypeLabel(String slot) {
  return slot
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String slotMoodEmoji(String slotType) {
  switch (slotType) {
    case 'brunch':
      return '🥂';
    case 'day_party':
      return '🌴';
    case 'lounge':
      return '🍸';
    case 'night':
      return '🍾';
    case 'after_hours':
      return '🌃';
    default:
      return '✨';
  }
}

/// Material icon for slot type — reliable on iOS when emoji fonts fail under Google Fonts.
IconData slotMoodIcon(String slotType) {
  switch (slotType) {
    case 'brunch':
      return Icons.brunch_dining_outlined;
    case 'day_party':
      return Icons.wb_sunny_outlined;
    case 'lounge':
      return Icons.local_bar_outlined;
    case 'night':
      return Icons.nightlife_outlined;
    case 'after_hours':
      return Icons.dark_mode_outlined;
    default:
      return Icons.auto_awesome_outlined;
  }
}

/// Emoji text that keeps color-emoji fallbacks (Urbanist alone drops glyphs on iOS).
Widget slotMoodGlyph(String slotType, {double size = 22, Color? color}) {
  return Text(
    slotMoodEmoji(slotType),
    style: TextStyle(
      fontSize: size,
      height: 1.1,
      color: color,
      fontFamilyFallback: const [
        'Apple Color Emoji',
        'Segoe UI Emoji',
        'Noto Color Emoji',
        'EmojiOne Color',
      ],
    ),
  );
}

String stopTimeLabel({String? scheduledLabel, String? arrivalWindow}) {
  final scheduled = scheduledLabel?.trim();
  if (scheduled != null && scheduled.isNotEmpty) return scheduled;
  final window = arrivalWindow?.trim() ?? '';
  if (window.isEmpty) return '';
  return window.split(RegExp(r'[–—-]')).first.trim();
}

/// Occasion entry keys matching web `/packages?vibe=`.
class OccasionVibe {
  const OccasionVibe({
    required this.key,
    required this.title,
    required this.icon,
    required this.overlayTop,
    required this.overlayBottom,
  });

  final String key;
  final String title;
  final IconData icon;
  final Color overlayTop;
  final Color overlayBottom;
}

const occasionVibes = <OccasionVibe>[
  OccasionVibe(
    key: 'date_night',
    title: 'Date Night',
    icon: Icons.favorite_rounded,
    overlayTop: Color(0xCC881337),
    overlayBottom: Color(0x99000000),
  ),
  OccasionVibe(
    key: 'girls_night',
    title: 'Girls Night Out',
    icon: Icons.groups_rounded,
    overlayTop: Color(0xCC3B0764),
    overlayBottom: Color(0x99000000),
  ),
  OccasionVibe(
    key: 'birthday',
    title: 'Birthday Celebration',
    icon: Icons.cake_rounded,
    overlayTop: Color(0xCC78350F),
    overlayBottom: Color(0x99000000),
  ),
  OccasionVibe(
    key: 'out_of_town',
    title: 'Out of Town Weekend',
    icon: Icons.flight_takeoff_rounded,
    overlayTop: Color(0xCC0F172A),
    overlayBottom: Color(0x99000000),
  ),
  OccasionVibe(
    key: 'luxury',
    title: 'Luxury Experience',
    icon: Icons.diamond_rounded,
    overlayTop: Color(0xCC1E1B4B),
    overlayBottom: Color(0x99000000),
  ),
];

bool matchesOccasionVibe({
  required String vibeKey,
  String? templateKey,
  String? title,
  String? slug,
  List<String> vibeTags = const [],
}) {
  final tags = vibeTags.map((t) => t.toLowerCase()).toList();
  final t = (title ?? '').toLowerCase();
  final s = (slug ?? '').toLowerCase();
  final template = (templateKey ?? '').toLowerCase();

  switch (vibeKey) {
    case 'date_night':
      return template == 'date_night' ||
          tags.any((x) => x.contains('date')) ||
          t.contains('date night');
    case 'girls_night':
      return tags.any((x) => x.contains('girl') || x.contains('ladies')) ||
          t.contains('girls') ||
          s.contains('girls');
    case 'birthday':
      return template == 'birthday' ||
          tags.any((x) => x.contains('birthday') || x.contains('bday')) ||
          t.contains('birthday');
    case 'out_of_town':
      return template == 'out_of_town' ||
          tags.any((x) => x.contains('visitor') || x.contains('weekend')) ||
          t.contains('out of town') ||
          s.contains('rooftop-escape') ||
          s.contains('out-of-town');
    case 'luxury':
      return tags.any((x) => x.contains('luxury') || x.contains('vip')) ||
          t.contains('luxury') ||
          template == 'lit_night';
    default:
      return template == vibeKey;
  }
}
