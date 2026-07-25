import 'package:flutter/material.dart';
import '../../config/app_brand.dart';
import '../../models/app_mode.dart';
import '../../navigation/mode_navigation.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';
import 'help_support_screen.dart';
import 'map_search_screen.dart';
import 'wtva_profile_screen.dart';
import 'photos_hub_screen.dart';
import 'wtva_notifications_screen.dart';
import 'search_screen.dart';
import 'drivers_browse_screen.dart';
import 'member_dashboard_screen.dart';
import 'night_packages_browse_screen.dart';
import 'venues_browse_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isGuest = UserService().isGuest;
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            AppBrand.name,
            style: const TextStyle(color: WtvaColors.neutral300, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (isGuest) ...[
            _GuestBanner(onSignIn: () => AccountGate.requireSignIn(context)),
            const SizedBox(height: 20),
          ],
          _MenuTile(
            icon: Icons.nightlife_outlined,
            title: 'Curated Vibes',
            subtitle: 'Build and book your night out',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NightPackagesBrowseScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.apartment_outlined,
            title: 'Venues',
            subtitle: 'Browse clubs, lounges & spots',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VenuesBrowseScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.directions_car_outlined,
            title: 'Find a driver',
            subtitle: 'Browse limo & driver listings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriversBrowseScreen()),
            ),
          ),
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
          if (!isGuest)
            _MenuTile(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              subtitle: 'Your plans, check-ins & shortcuts',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MemberDashboardScreen(),
                ),
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
      ),
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
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.person_outline, color: WtvaColors.neutral200, size: 32),
              SizedBox(width: 12),
              Expanded(
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
                      'Sign up to check in, message venues, and save your profile.',
                      style: TextStyle(fontSize: 13, color: WtvaColors.neutral300),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: WtvaColors.neutral300),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: WtvaColors.dark400,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: WtvaColors.neutral200),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
          ),
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
      ),
    );
  }
}
