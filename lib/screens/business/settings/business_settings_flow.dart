import 'package:flutter/material.dart';
import '../../../config/app_brand.dart';
import '../../../models/app_mode.dart';
import '../../../models/business/business_models.dart';
import '../../../navigation/mode_navigation.dart';
import '../../../services/business_service.dart';
import '../../../services/user_service.dart';
import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';
import '../../../widgets/business/business_widgets.dart';
import '../../../widgets/wtva/neighborhood_dropdown.dart';
import '../../../widgets/wtva/wtva_gradient_button.dart';
import '../../wtva/help_support_screen.dart';
import '../../wtva/settings/extended_settings_screens.dart';
import '../business_login_screen.dart';
import '../payments/business_payments_flow.dart';
import '../analytics/business_analytics_flow.dart';
import '../bookings/business_bookings_flow.dart';

/// #03 More menu + account, help, rate, share.
class BusinessMoreScreen extends StatelessWidget {
  const BusinessMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserService().currentUser;
    final profile = BusinessService.instance.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Text('More', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        if (user != null) ...[
          const SizedBox(height: 4),
          Text(user.name, style: const TextStyle(color: WtvaColors.neutral300, fontSize: 13)),
          Text(profile.venueName, style: const TextStyle(color: WtvaColors.neutral300, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        BusinessMenuTile(
          icon: Icons.storefront_outlined,
          title: 'Business profile',
          subtitle: profile.verified ? 'Verified · demo' : 'Complete verification',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessEditProfileScreen())),
        ),
        BusinessMenuTile(
          icon: Icons.insights_outlined,
          title: 'Analytics',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessAnalyticsScreen())),
        ),
        BusinessMenuTile(
          icon: Icons.event_note_outlined,
          title: 'Booking history',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessBookingsScreen())),
        ),
        BusinessMenuTile(
          icon: Icons.payments_outlined,
          title: 'Payments',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessPaymentsScreen())),
        ),
        BusinessMenuTile(
          icon: Icons.settings_outlined,
          title: 'Account settings',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessAccountSettingsScreen())),
        ),
        BusinessMenuTile(
          icon: Icons.help_outline,
          title: 'Help centre',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessHelpCentreScreen())),
        ),
        BusinessMenuTile(
          icon: Icons.star_outline,
          title: 'Rate the app',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessRateAppScreen())),
        ),
        BusinessMenuTile(
          icon: Icons.share_outlined,
          title: 'Share app with friends',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessShareAppScreen())),
        ),
        const SizedBox(height: 8),
        BusinessMenuTile(
          icon: Icons.nightlife_outlined,
          title: 'Switch to customer',
          subtitle: 'Discover, check in, rank up',
          onTap: () => ModeNavigation.switchToMode(context, AppMode.customer),
        ),
        BusinessMenuTile(
          icon: Icons.swap_horiz,
          title: 'Change mode',
          onTap: () => ModeNavigation.openModePicker(context),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            UserService().logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const BusinessLoginScreen()),
              (_) => false,
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: WtvaColors.neutral200,
            side: const BorderSide(color: WtvaColors.night200),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}

class BusinessAccountSettingsScreen extends StatelessWidget {
  const BusinessAccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Account settings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          BusinessMenuTile(
            icon: Icons.email_outlined,
            title: 'Change email',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WtvaChangeEmailScreen())),
          ),
          BusinessMenuTile(
            icon: Icons.lock_outline,
            title: 'Change password',
            onTap: () => showWtvaSnack(context, 'Use forgot password from login (demo)'),
          ),
          BusinessMenuTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessNotificationsScreen())),
          ),
          BusinessMenuTile(
            icon: Icons.switch_account,
            title: 'Switch account',
            subtitle: 'Other business accounts',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessSwitchAccountScreen())),
          ),
        ],
      ),
    );
  }
}

class BusinessNotificationsScreen extends StatefulWidget {
  const BusinessNotificationsScreen({super.key});

  @override
  State<BusinessNotificationsScreen> createState() => _BusinessNotificationsScreenState();
}

class _BusinessNotificationsScreenState extends State<BusinessNotificationsScreen> {
  bool _bookings = true;
  bool _checkIns = true;
  bool _promos = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            title: const Text('Booking updates'),
            value: _bookings,
            onChanged: (v) => setState(() => _bookings = v),
          ),
          SwitchListTile(
            title: const Text('Check-ins'),
            value: _checkIns,
            onChanged: (v) => setState(() => _checkIns = v),
          ),
          SwitchListTile(
            title: const Text('Promotion performance'),
            value: _promos,
            onChanged: (v) => setState(() => _promos = v),
          ),
        ],
      ),
    );
  }
}

class BusinessEditProfileScreen extends StatefulWidget {
  const BusinessEditProfileScreen({super.key});

  @override
  State<BusinessEditProfileScreen> createState() => _BusinessEditProfileScreenState();
}

class _BusinessEditProfileScreenState extends State<BusinessEditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  String? _neighborhood;
  late final TextEditingController _phone;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final p = BusinessService.instance.profile;
    _name = TextEditingController(text: p.venueName);
    _address = TextEditingController(text: p.address);
    _neighborhood = p.neighborhood.isEmpty ? null : p.neighborhood;
    _phone = TextEditingController(text: p.phone);
    _bio = TextEditingController(text: p.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Business profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Venue name')),
          const SizedBox(height: 16),
          NeighborhoodDropdown(
            value: _neighborhood,
            onChanged: (value) => setState(() => _neighborhood = value),
          ),
          const SizedBox(height: 16),
          TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 16),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 16),
          TextField(controller: _bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 24),
          WtvaGradientButton(
            label: 'Save',
            onPressed: () {
              final p = BusinessService.instance.profile;
              BusinessService.instance.updateProfile(BusinessVenueProfile(
                venueName: _name.text.trim(),
                address: _address.text.trim(),
                neighborhood: _neighborhood ?? '',
                phone: _phone.text.trim(),
                description: _bio.text.trim(),
                categories: p.categories,
                serviceOptions: p.serviceOptions,
                tier: p.tier,
                verified: p.verified,
              ));
              Navigator.pop(context);
              showWtvaSnack(context, 'Profile saved (demo)');
            },
          ),
        ],
      ),
    );
  }
}

class BusinessHelpCentreScreen extends StatelessWidget {
  const BusinessHelpCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Help centre', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          BusinessMenuTile(
            icon: Icons.quiz_outlined,
            title: 'FAQs',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
          ),
          BusinessMenuTile(
            icon: Icons.article_outlined,
            title: 'How bookings work',
            onTap: () => _article(context, 'Bookings', 'Browse ranked users, send paid invites, and track confirmation through check-in.'),
          ),
          BusinessMenuTile(
            icon: Icons.mail_outline,
            title: 'Email support',
            onTap: () => showWtvaSnack(context, 'support@wherethevibesat.com', icon: Icons.email),
          ),
        ],
      ),
    );
  }

  void _article(BuildContext context, String title, String body) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: WtvaColors.dark500,
          appBar: AppBar(backgroundColor: WtvaColors.dark500, title: Text(title)),
          body: Padding(padding: const EdgeInsets.all(20), child: Text(body, style: const TextStyle(height: 1.5))),
        ),
      ),
    );
  }
}

class BusinessRateAppScreen extends StatefulWidget {
  const BusinessRateAppScreen({super.key});

  @override
  State<BusinessRateAppScreen> createState() => _BusinessRateAppScreenState();
}

class _BusinessRateAppScreenState extends State<BusinessRateAppScreen> {
  int _stars = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(backgroundColor: WtvaColors.dark500, title: const Text('Rate the app')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('How is the business portal?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  icon: Icon(i < _stars ? Icons.star : Icons.star_border, size: 36, color: WtvaColors.neutral50),
                  onPressed: () => setState(() => _stars = i + 1),
                ),
              ),
            ),
            const Spacer(),
            WtvaGradientButton(
              label: 'Submit',
              onPressed: () {
                Navigator.pop(context);
                showWtvaSnack(context, 'Thanks for your feedback!');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BusinessShareAppScreen extends StatelessWidget {
  const BusinessShareAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(backgroundColor: WtvaColors.dark500, title: const Text('Share app')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Invite other venues to ${AppBrand.name}.', style: const TextStyle(color: WtvaColors.neutral300)),
            const SizedBox(height: 24),
            WtvaGradientButton(
              label: 'Share link (demo)',
              onPressed: () => showWtvaSnack(context, 'Link copied (demo)', icon: Icons.share),
            ),
          ],
        ),
      ),
    );
  }
}

class BusinessSwitchAccountScreen extends StatelessWidget {
  const BusinessSwitchAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(backgroundColor: WtvaColors.dark500, title: const Text('Switch account')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.store)),
            title: const Text('Post Oak Bar'),
            subtitle: const Text('Current'),
            trailing: const Icon(Icons.check, color: WtvaColors.neutral50),
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.store_outlined)),
            title: const Text('Add another business'),
            onTap: () => showWtvaSnack(context, 'Multi-venue — demo'),
          ),
        ],
      ),
    );
  }
}
