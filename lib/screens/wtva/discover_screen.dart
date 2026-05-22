import 'package:flutter/material.dart';
import '../../config/app_brand.dart';
import '../../data/mock_discover_data.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_category_chips.dart';
import '../../widgets/wtva/wtva_live_stories.dart';
import '../../widgets/wtva/wtva_promoted_card.dart';
import '../../widgets/wtva/wtva_search_bar.dart';
import '../../widgets/wtva/wtva_venue_card.dart';
import '../../data/mock_venue_store.dart';
import 'map_search_screen.dart';
import 'venue_detail_screen.dart';
import 'search_screen.dart';
import 'wtva_notifications_screen.dart';
import 'profile/user_profile_screen.dart';
import '../../utils/wtva_user_helpers.dart';
import 'city_picker_sheet.dart';
import '../../utils/account_gate.dart';
import '../../utils/wtva_feedback.dart';
import 'go_live_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _categoryIndex = 0;
  String _city = 'Houston, TX';

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final user = userService.currentUser;
    final displayName = userService.isGuest
        ? 'Guest'
        : (user?.name ?? (user?.email.isNotEmpty == true ? user!.email.split('@').first : 'Guest'));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discover',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => CityPickerSheet.show(
                              context,
                              selected: _city,
                              onSelected: (c) {
                                setState(() => _city = c);
                                if (c != 'Houston, TX') {
                                  showWtvaSnack(
                                    context,
                                    'Demo venues are Houston-only — still showing Houston',
                                    icon: Icons.location_city,
                                  );
                                }
                              },
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: WtvaColors.neutral200),
                                const SizedBox(width: 4),
                                Text(
                                  _city,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: WtvaColors.neutral200,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, color: WtvaColors.neutral300, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 22,
                      onPressed: () async {
                        if (!await AccountGate.requireSignIn(context)) return;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WtvaNotificationsScreen()),
                        );
                      },
                      icon: const Icon(Icons.notifications_outlined, color: WtvaColors.neutral200),
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (!await AccountGate.requireSignIn(context)) return;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(
                              user: socialUserFromSession(),
                              isSelf: true,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: WtvaColors.dark300,
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: WtvaColors.accentPurple,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                WtvaSearchBar(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                  onFilterTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapSearchScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                WtvaCategoryChips(
                  categories: MockDiscoverData.categories,
                  selectedIndex: _categoryIndex,
                  onSelected: (i) {
                    if (MockDiscoverData.categories[i] == 'Location') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapSearchScreen()),
                      ).then((_) {
                        if (mounted) setState(() => _categoryIndex = 0);
                      });
                      return;
                    }
                    setState(() => _categoryIndex = i);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Promoted',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                      child: Text(
                        'See all',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: WtvaColors.accentPurple,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                WtvaPromotedCard(
                  offer: MockDiscoverData.promoted,
                  onTap: () {
                    final detail = MockVenueStore.byName(MockDiscoverData.promoted.venueName);
                    if (detail != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VenueDetailScreen(venueId: detail.venue.id),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Near you',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final filtered = MockDiscoverData.venuesForCategory(_categoryIndex);
              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No venues in this category', style: TextStyle(color: WtvaColors.neutral300)),
                  ),
                );
              }
              final venue = filtered[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: WtvaVenueCard(
                  venue: venue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VenueDetailScreen(venueId: venue.id),
                      ),
                    );
                  },
                ),
              );
            },
            childCount: MockDiscoverData.venuesForCategory(_categoryIndex).isEmpty
                ? 1
                : MockDiscoverData.venuesForCategory(_categoryIndex).length,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live at venues',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      AppBrand.tagline,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: WtvaColors.neutral300,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                WtvaLiveStories(
                  stories: MockDiscoverData.liveStories,
                  onStoryTap: (story) async {
                    if (!await AccountGate.requireSignIn(context)) return;
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GoLiveScreen(venueId: '4'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
