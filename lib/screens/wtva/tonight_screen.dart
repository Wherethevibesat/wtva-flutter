import 'package:flutter/material.dart';
import '../../data/tonight_feed.dart';
import '../../data/wtva_cities.dart';
import '../../services/events_repository.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/home_hero_search.dart';
import '../../widgets/wtva/tonight_event_card.dart';
import '../../utils/account_gate.dart';
import 'city_picker_sheet.dart';
import 'concierge_sheet.dart';
import 'event_detail_screen.dart';
import 'events_browse_screen.dart';
import 'more_screen.dart';
import 'night_packages_browse_screen.dart';
import 'search_screen.dart';
import 'tip_night_sheet.dart';
import 'wtva_notifications_screen.dart';
import 'wtva_profile_screen.dart';

class TonightScreen extends StatefulWidget {
  const TonightScreen({super.key});

  @override
  State<TonightScreen> createState() => _TonightScreenState();
}

class _TonightScreenState extends State<TonightScreen> {
  String _city = WtvaCities.defaultCity.label;
  int _moodIndex = 0;
  int _eventsTab = 0; // 0 Featured, 1 Upcoming
  List<WtvaEventRecord> _events = const [];
  bool _loading = true;

  static const _moods = [
    (label: 'For You', icon: Icons.local_fire_department_rounded),
    (label: 'Afrobeats', icon: Icons.album_rounded),
    (label: 'Happy Hour', icon: Icons.local_bar_rounded),
    (label: 'After Hours', icon: Icons.nights_stay_rounded),
    (label: 'Rooftops', icon: Icons.apartment_rounded),
    (label: 'VIP', icon: Icons.workspace_premium_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await EventsRepository.instance.listPublished(limit: 40);
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  String get _firstName {
    final user = UserService().currentUser;
    if (UserService().isGuest) return 'there';
    return TonightFeed.firstName(user?.name);
  }

  void _onMoodTap(int index) {
    setState(() => _moodIndex = index);
    final label = _moods[index].label;
    if (label == 'For You') return;

    // Map mood chips to real browse filters (event type or text search).
    final (:eventType, :query) = switch (label) {
      'Happy Hour' => (eventType: 'Happy Hours', query: null),
      'After Hours' => (eventType: 'After Hours', query: null),
      'Afrobeats' => (eventType: null, query: 'Afrobeats'),
      'Rooftops' => (eventType: null, query: 'Rooftop'),
      'VIP' => (eventType: null, query: 'VIP'),
      _ => (eventType: null, query: label),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventsBrowseScreen(
          initialEventType: eventType,
          initialQuery: query,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = TonightFeed.featuredEvents(_events);
    final upcoming = TonightFeed.upcomingEvents(_events);
    final activeEvents = _eventsTab == 0 ? featured : upcoming;
    final vibes = TonightFeed.vibes(eventCount: _events.length);

    return RefreshIndicator(
      color: WtvaColors.accentPurple,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              city: _city,
              firstName: _firstName,
              moodIndex: _moodIndex,
              moods: _moods,
              onMoodTap: _onMoodTap,
              onCityTap: () => CityPickerSheet.show(
                context,
                selected: _city,
                onSelected: (c) => setState(() => _city = c),
              ),
              onNotify: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WtvaNotificationsScreen()),
              ),
              onProfile: () async {
                if (!await AccountGate.requireSignIn(
                  context,
                  message: 'Log in or sign up to view your profile.',
                )) {
                  return;
                }
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WtvaProfileScreen()),
                );
              },
              onMore: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoreScreen()),
              ),
              onSearch: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SpacedSliver(
            0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Explore Houston',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EventsBrowseScreen()),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: WtvaColors.accentPurple,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'See all',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SpacedSliver(12),
          SpacedSliver(
            0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _EventsTabBar(
                index: _eventsTab,
                onChanged: (i) => setState(() => _eventsTab = i),
              ),
            ),
          ),
          const SpacedSliver(14),
          SliverToBoxAdapter(
            child: SizedBox(
              height: activeEvents.isEmpty && !_loading
                  ? null
                  : (_eventsTab == 0 ? 248.0 : 196.0),
              child: _loading
                  ? const SizedBox(
                      height: 196,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : activeEvents.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _EmptyEventsCard(
                            onTip: () => TipNightSheet.show(context, source: 'empty_feed'),
                            onBrowse: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EventsBrowseScreen()),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: activeEvents.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final item = activeEvents[i];
                            return TonightEventCard(
                              item: item,
                              featured: _eventsTab == 0,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventDetailScreen(eventId: item.eventId),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
          const SpacedSliver(28),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TipNightBanner(
                onTap: () => TipNightSheet.show(context, source: 'empty_feed'),
              ),
            ),
          ),
          const SpacedSliver(28),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _PlanNightCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NightPackagesBrowseScreen(),
                  ),
                ),
              ),
            ),
          ),
          const SpacedSliver(28),
          SliverToBoxAdapter(
            child: _ConciergeCard(
              onAsk: () => ConciergeSheet.show(context),
            ),
          ),
          const SpacedSliver(28),
          SpacedSliver(
            0,
            child: _SectionHeader(
              title: 'Explore by vibe',
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventsBrowseScreen()),
              ),
            ),
          ),
          const SpacedSliver(12),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 112,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: vibes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final vibe = vibes[i];
                  return _VibeTile(
                    label: vibe.label,
                    countLabel: vibe.countLabel,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventsBrowseScreen(initialEventType: vibe.query),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SpacedSliver(120),
        ],
      ),
    );
  }
}

/// Tiny helper for vertical spacing slivers.
class SpacedSliver extends StatelessWidget {
  const SpacedSliver(this.height, {super.key, this.child});

  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) return SliverToBoxAdapter(child: child);
    return SliverToBoxAdapter(child: SizedBox(height: height));
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.city,
    required this.firstName,
    required this.moodIndex,
    required this.moods,
    required this.onMoodTap,
    required this.onCityTap,
    required this.onNotify,
    required this.onProfile,
    required this.onMore,
    required this.onSearch,
  });

  final String city;
  final String firstName;
  final int moodIndex;
  final List<({String label, IconData icon})> moods;
  final ValueChanged<int> onMoodTap;
  final VoidCallback onCityTap;
  final VoidCallback onNotify;
  final VoidCallback onProfile;
  final VoidCallback onMore;
  final VoidCallback onSearch;

  static const _heroImage =
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1400&q=80';

  @override
  Widget build(BuildContext context) {
    final greeting = TonightFeed.greetingFor(DateTime.now());
    final topPad = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                _heroImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE9D5FF), Color(0xFFFBCFE8), Color(0xFFF6F6F9)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF2A0B45).withValues(alpha: 0.62),
                      const Color(0xFF3B0764).withValues(alpha: 0.58),
                      const Color(0xFF4A044E).withValues(alpha: 0.72),
                      const Color(0xFFF6F6F9),
                    ],
                    stops: const [0.0, 0.4, 0.72, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, topPad + 4, 0, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: onCityTap,
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 18, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                city,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white70),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onSearch,
                          icon: const Icon(Icons.search, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: onNotify,
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: onProfile,
                          tooltip: 'Profile',
                          icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: onMore,
                          tooltip: 'More',
                          icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$greeting, $firstName',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.waving_hand_rounded, size: 16, color: Color(0xFFF59E0B)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                            children: [
                              const TextSpan(text: "What's the move "),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Text(
                                      'tonight?',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: -0.8,
                                        color: const Color(0xFFF0ABFC)
                                            .withValues(alpha: 0.55),
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFFDB2777)
                                                .withValues(alpha: 0.65),
                                            blurRadius: 20,
                                          ),
                                          Shadow(
                                            color: const Color(0xFF7C3AED)
                                                .withValues(alpha: 0.45),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                    ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFE9D5FF),
                                              Color(0xFFF0ABFC),
                                              Color(0xFFF9A8D4),
                                            ],
                                          ).createShader(bounds),
                                      child: const Text(
                                        'tonight?',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white,
                                          letterSpacing: -0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Find events, clubs, VIP experiences—all in one place.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const HomeHeroSearch(onDark: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 88,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: moods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final selected = i == moodIndex;
              final mood = moods[i];
              return GestureDetector(
                onTap: () => onMoodTap(i),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: selected ? WtvaColors.buttonGradient : null,
                        color: selected ? null : WtvaColors.dark400,
                        border: selected
                            ? null
                            : Border.all(color: WtvaColors.night200),
                        boxShadow: selected ? WtvaColors.buttonShadow : null,
                      ),
                      child: Icon(
                        mood.icon,
                        color: selected ? Colors.white : WtvaColors.accentPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mood.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? WtvaColors.accentPurple : WtvaColors.neutral200,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyEventsCard extends StatelessWidget {
  const _EmptyEventsCard({required this.onTip, required this.onBrowse});

  final VoidCallback onTip;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WtvaColors.night200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No events listed yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'When venues publish nights, they’ll show up here. Tip a night so we know what to book.',
            style: TextStyle(color: WtvaColors.neutral200, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBrowse,
                  child: const Text('Browse events'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: WtvaColors.buttonGradient,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton(
                    onPressed: onTip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text(
                      'Tip a night',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventsTabBar extends StatelessWidget {
  const _EventsTabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Featured', 'Upcoming'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: WtvaColors.night200),
        boxShadow: WtvaColors.cardShadow,
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: i == index ? WtvaColors.buttonGradient : null,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: i == index ? WtvaColors.onPrimary : WtvaColors.neutral200,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TipNightBanner extends StatelessWidget {
  const _TipNightBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: WtvaColors.night200),
            boxShadow: WtvaColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: WtvaColors.buttonGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What’s the move?',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tip a night or vibe — we’ll build the calendar from it.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: WtvaColors.neutral200,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: WtvaColors.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanNightCard extends StatelessWidget {
  const _PlanNightCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: WtvaColors.night200),
            boxShadow: WtvaColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: WtvaColors.buttonGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build Your Night',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Templates you can swap, add to, and pay once.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: WtvaColors.neutral200,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: WtvaColors.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConciergeCard extends StatelessWidget {
  const _ConciergeCard({required this.onAsk});

  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: WtvaColors.buttonGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: WtvaColors.buttonShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Vibes Concierge',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tell us the vibe you want — music, neighborhood, budget — and we’ll match real events and venues.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                onTap: onAsk,
                borderRadius: BorderRadius.circular(28),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Ask Concierge →',
                    style: TextStyle(
                      color: WtvaColors.accentPurple,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WtvaColors.neutral50,
              ),
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'See all',
              style: TextStyle(
                color: WtvaColors.accentPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VibeTile extends StatelessWidget {
  const _VibeTile({
    required this.label,
    required this.countLabel,
    required this.onTap,
  });

  final String label;
  final String countLabel;
  final VoidCallback onTap;

  IconData get _icon {
    switch (label) {
      case 'Afrobeats':
        return Icons.album_rounded;
      case 'Rooftops':
        return Icons.apartment_rounded;
      case 'Day Parties':
        return Icons.wb_sunny_rounded;
      case 'Brunch':
        return Icons.brunch_dining_rounded;
      case 'VIP':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.nights_stay_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WtvaColors.dark400,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WtvaColors.night200),
          boxShadow: WtvaColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: WtvaColors.accentPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, size: 18, color: WtvaColors.accentPurple),
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: WtvaColors.neutral50,
              ),
            ),
            if (countLabel.trim().isNotEmpty)
              Text(
                countLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: WtvaColors.neutral300,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
