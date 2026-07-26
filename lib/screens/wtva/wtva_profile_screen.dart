import 'package:flutter/material.dart';

import '../../config/dev_auth_config.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';
import '../../utils/wtva_user_helpers.dart';
import '../admin/admin_dashboard_screen.dart';
import 'profile/user_profile_screen.dart';
import 'wtva_check_in_history_screen.dart';
import 'wtva_edit_profile_screen.dart';
import 'wtva_favorites_screen.dart';
import 'wtva_login_screen.dart';
import 'wtva_settings_screen.dart';

class WtvaProfileScreen extends StatelessWidget {
  const WtvaProfileScreen({super.key, this.embedded = false});

  /// When true (bottom-nav tab), hide the back chevron.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final user = userService.currentUser;
    final isGuest = userService.isGuest;
    final name = isGuest ? 'Guest' : (user?.name ?? user?.email ?? 'Guest');
    final email = isGuest ? '' : (user?.email ?? '');
    final role = isGuest ? 'Browsing' : (user?.role.displayName ?? 'Customer');
    final isAdmin = !isGuest && user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        elevation: 0,
        automaticallyImplyLeading: !embedded,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: WtvaColors.dark300,
              backgroundImage:
                  user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null,
              child: user?.profileImageUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.accentPurple,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (isGuest) ...[
            const SizedBox(height: 8),
            const Text(
              'Browse only — sign up to check in, save favorites, and message venues.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WtvaColors.neutral300, fontSize: 13, height: 1.35),
            ),
          ] else if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WtvaColors.neutral300),
            ),
            const SizedBox(height: 6),
            Text(
              role,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: WtvaColors.neutral300,
              ),
            ),
          ],
          const SizedBox(height: 28),
          _ProfileTile(
            icon: Icons.account_circle_outlined,
            title: 'View profile',
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
          ),
          _ProfileTile(
            icon: Icons.person_outline,
            title: 'Edit profile',
            onTap: () async {
              if (!await AccountGate.requireSignIn(context)) return;
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WtvaEditProfileScreen()),
              );
            },
          ),
          _ProfileTile(
            icon: Icons.favorite_border,
            title: 'Favorites',
            onTap: () async {
              if (!await AccountGate.requireSignIn(context)) return;
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WtvaFavoritesScreen()),
              );
            },
          ),
          _ProfileTile(
            icon: Icons.history,
            title: 'Check-in history',
            onTap: () async {
              if (!await AccountGate.requireSignIn(context)) return;
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WtvaCheckInHistoryScreen()),
              );
            },
          ),
          _ProfileTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaSettingsScreen()),
            ),
          ),
          if (isAdmin)
            _ProfileTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admin dashboard',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              if (isGuest) {
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WtvaLoginScreen()),
                  (_) => false,
                );
                return;
              }
              if (!DevAuthConfig.useDummyAuth) {
                await AuthService().signOut();
              }
              UserService().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WtvaLoginScreen()),
                  (_) => false,
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: WtvaColors.accentPink,
              side: const BorderSide(color: WtvaColors.accentPink),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(isGuest ? 'Log in or sign up' : 'Sign out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: WtvaColors.neutral200),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
          onTap: onTap,
        ),
      ),
    );
  }
}
