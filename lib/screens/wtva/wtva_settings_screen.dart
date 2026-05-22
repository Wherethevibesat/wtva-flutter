import 'package:flutter/material.dart';
import '../../config/dev_auth_config.dart';
import '../../models/app_mode.dart';
import '../../navigation/mode_navigation.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/account_gate.dart';
import '../../theme/figma_theme.dart';
import 'settings/extended_settings_screens.dart';
import 'wtva_edit_profile_screen.dart';
import 'wtva_forgot_password_screen.dart';
import 'wtva_login_screen.dart';

class WtvaSettingsScreen extends StatefulWidget {
  const WtvaSettingsScreen({super.key});

  @override
  State<WtvaSettingsScreen> createState() => _WtvaSettingsScreenState();
}

class _WtvaSettingsScreenState extends State<WtvaSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isGuest = UserService().isGuest;
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (isGuest) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WtvaColors.dark400,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WtvaColors.night200),
              ),
              child: const Text(
                'You\'re browsing as a guest. Sign up or log in to manage your account.',
                style: TextStyle(color: WtvaColors.neutral200, height: 1.35),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => AccountGate.requireSignIn(context),
              style: FilledButton.styleFrom(
                backgroundColor: WtvaColors.accentGreen,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Log in or sign up'),
            ),
            const SizedBox(height: 20),
          ] else ...[
          const _SectionLabel('Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Edit profile',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaEditProfileScreen()),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Notifications'),
          _SwitchTile(
            title: 'Push notifications',
            subtitle: 'Invites, check-ins, messages',
            value: _pushEnabled,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
          _SwitchTile(
            title: 'Email updates',
            subtitle: 'Weekly digest & promotions',
            value: _emailEnabled,
            onChanged: (v) => setState(() => _emailEnabled = v),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Privacy'),
          _SwitchTile(
            title: 'Share location',
            subtitle: 'For nearby venues & check-ins',
            value: _locationEnabled,
            onChanged: (v) => setState(() => _locationEnabled = v),
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Change email',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaChangeEmailScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Account settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaAccountSettingsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change password',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaForgotPasswordScreen()),
            ),
          ),
          const SizedBox(height: 20),
          ],
          const _SectionLabel('Payments & app'),
          _SettingsTile(
            icon: Icons.payments_outlined,
            title: 'Payments',
            subtitle: 'Payouts and cards',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaPaymentsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            title: 'Rate the app',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaRateAppScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.share_outlined,
            title: 'Share the app',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaShareAppScreen()),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Mode'),
          _SettingsTile(
            icon: Icons.storefront_outlined,
            title: 'Switch to business',
            subtitle: 'Venue portal — promos, bookings, analytics',
            onTap: () => ModeNavigation.switchToMode(context, AppMode.business),
          ),
          _SettingsTile(
            icon: Icons.swap_horiz,
            title: 'Change mode',
            subtitle: 'Customer or business',
            onTap: () => ModeNavigation.openModePicker(context),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('About'),
          const _SettingsTile(
            icon: Icons.info_outline,
            title: 'App version',
            subtitle: '1.0.0 · wherethevibesat',
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
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WtvaLoginScreen()),
                (_) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: WtvaColors.neutral200,
              side: const BorderSide(color: WtvaColors.night200),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(isGuest ? 'Back to log in' : 'Sign out'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: WtvaColors.neutral300,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: WtvaColors.neutral200),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300))
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: WtvaColors.neutral300)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
        value: value,
        activeThumbColor: WtvaColors.neutral50,
        onChanged: onChanged,
      ),
    );
  }
}
