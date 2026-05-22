import 'package:flutter/material.dart';
import '../../config/app_brand.dart';
import '../../models/app_mode.dart';
import '../../navigation/mode_navigation.dart';
import '../../services/ranking_service.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';
import 'help_support_screen.dart';
import 'map_search_screen.dart';
import 'wtva_profile_screen.dart';
import 'photos_hub_screen.dart';
import 'wtva_notifications_screen.dart';
import 'ranking_screen.dart';
import 'search_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isGuest = UserService().isGuest;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Text(
          'More',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          AppBrand.name,
          style: const TextStyle(color: WtvaColors.neutral300, fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (isGuest)
          _GuestBanner(
            onSignIn: () => AccountGate.requireSignIn(context),
          )
        else
          _PointsBanner(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RankingScreen()),
            ),
          ),
        const SizedBox(height: 20),
        _MenuTile(
          icon: Icons.search,
          title: 'Search',
          subtitle: 'Venues, people & tags',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
        _MenuTile(
          icon: Icons.map_outlined,
          title: 'Map search',
          subtitle: 'Find venues on the map',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapSearchScreen()),
          ),
        ),
        _MenuTile(
          icon: Icons.person_outline,
          title: 'Profile',
          subtitle: isGuest ? 'Sign in to view your profile' : 'Your account, posts & settings',
          onTap: () async {
            if (isGuest) {
              await AccountGate.requireSignIn(context);
              return;
            }
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaProfileScreen()),
            );
          },
        ),
        _MenuTile(
          icon: Icons.camera_alt_outlined,
          title: 'Photos & videos',
          subtitle: isGuest ? 'Sign in to upload and save media' : 'Your nightlife gallery',
          onTap: () async {
            if (isGuest) {
              await AccountGate.requireSignIn(context);
              return;
            }
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PhotosHubScreen()),
            );
          },
        ),
        _MenuTile(
          icon: Icons.storefront_outlined,
          title: 'Switch to business',
          subtitle: 'Venue dashboard, promos & bookings',
          onTap: () => ModeNavigation.switchToMode(context, AppMode.business),
        ),
        _MenuTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: isGuest ? 'Sign in for alerts & invites' : 'Alerts & invites',
          onTap: () async {
            if (isGuest) {
              await AccountGate.requireSignIn(context);
              return;
            }
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaNotificationsScreen()),
            );
          },
        ),
        _MenuTile(
          icon: Icons.help_outline,
          title: 'Help & support',
          subtitle: 'FAQ and contact',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'v1.0 · wherethevibesat',
            style: TextStyle(fontSize: 11, color: WtvaColors.neutral300),
          ),
        ),
      ],
    );
  }
}

class _GuestBanner extends StatelessWidget {
  final VoidCallback onSignIn;

  const _GuestBanner({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onSignIn,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: WtvaColors.neutral200, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browsing as Guest',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sign up to earn points, message venues, and save your profile.',
                      style: TextStyle(fontSize: 13, color: WtvaColors.neutral300),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointsBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const _PointsBanner({this.onTap});

  @override
  Widget build(BuildContext context) {
    final ranking = RankingService.instance;
    return ListenableBuilder(
      listenable: ranking,
      builder: (context, _) => GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: WtvaColors.buttonGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: WtvaColors.onPrimary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.currentRank,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: WtvaColors.onPrimary,
                  ),
                ),
                Text(
                  '${ranking.currentPoints} points',
                  style: TextStyle(
                    fontSize: 13,
                    color: WtvaColors.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: WtvaColors.onPrimary.withValues(alpha: 0.5)),
        ],
      ),
    ),
    ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WtvaColors.night200.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: WtvaColors.neutral200),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
        trailing: const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
      ),
    );
  }
}
