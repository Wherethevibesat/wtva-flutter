import 'package:flutter/material.dart';
import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';
import '../../../widgets/wtva/wtva_gradient_button.dart';
import '../wtva_forgot_password_screen.dart';

class WtvaPaymentsScreen extends StatelessWidget {
  const WtvaPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Payments', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Tile(
            Icons.account_balance,
            'Add bank or PayPal',
            'Get paid for venue invites',
            onTap: () => showWtvaSnack(context, 'Payout setup opens after backend is connected', icon: Icons.account_balance),
          ),
          _Tile(
            Icons.credit_card,
            'Payment methods',
            'Cards on file',
            onTap: () => showWtvaSnack(context, 'No cards on file (demo)', icon: Icons.credit_card),
          ),
          _Tile(
            Icons.receipt_long,
            'Earnings history',
            'View payouts',
            onTap: () => showWtvaSnack(context, 'No payouts yet — check in at paid invites', icon: Icons.receipt_long),
          ),
        ],
      ),
    );
  }
}

class WtvaRateAppScreen extends StatefulWidget {
  const WtvaRateAppScreen({super.key});

  @override
  State<WtvaRateAppScreen> createState() => _WtvaRateAppScreenState();
}

class _WtvaRateAppScreenState extends State<WtvaRateAppScreen> {
  int _stars = 4;
  final _review = TextEditingController();

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Rate the app', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('How was your experience?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(i < _stars ? Icons.star : Icons.star_border, color: WtvaColors.accentGreen, size: 36),
                  onPressed: () => setState(() => _stars = i + 1),
                );
              }),
            ),
            TextField(
              controller: _review,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Write a review (optional)'),
            ),
            const Spacer(),
            WtvaGradientButton(
              label: 'Submit',
              onPressed: () {
                Navigator.pop(context);
                showWtvaSnack(context, 'Thanks for your feedback!', icon: Icons.star);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WtvaShareAppScreen extends StatelessWidget {
  const WtvaShareAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Share app', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Invite friends to Where The Vibes At',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You both earn bonus points when they sign up',
              textAlign: TextAlign.center,
              style: TextStyle(color: WtvaColors.neutral300),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => copyToClipboard(
                context,
                'https://wherethevibesat.com/invite/you',
                message: 'Invite link copied',
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WtvaColors.dark400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Expanded(child: Text('wherethevibesat.com/invite/you')),
                    Icon(Icons.copy, color: WtvaColors.lavender300),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            WtvaGradientButton(
              label: 'Share link',
              onPressed: () => copyToClipboard(
                context,
                'https://wherethevibesat.com/invite/you',
                message: 'Invite link copied',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WtvaChangeEmailScreen extends StatefulWidget {
  const WtvaChangeEmailScreen({super.key});

  @override
  State<WtvaChangeEmailScreen> createState() => _WtvaChangeEmailScreenState();
}

class _WtvaChangeEmailScreenState extends State<WtvaChangeEmailScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Change email', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'New email address'),
            ),
            const SizedBox(height: 24),
            WtvaGradientButton(
              label: 'Send confirmation',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WtvaConfirmEmailScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WtvaConfirmEmailScreen extends StatelessWidget {
  const WtvaConfirmEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(backgroundColor: WtvaColors.dark500),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mark_email_read_outlined, size: 64, color: WtvaColors.accentPurple),
              SizedBox(height: 16),
              Text('Confirm your email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text(
                'We sent a link to your inbox. Tap it to verify your new email.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WtvaColors.neutral300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WtvaAccountSettingsScreen extends StatelessWidget {
  const WtvaAccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Account settings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Tile(Icons.email_outlined, 'Change email', '', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WtvaChangeEmailScreen()));
          }),
          _Tile(
            Icons.lock_outline,
            'Change password',
            '',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaForgotPasswordScreen()),
            ),
          ),
          _Tile(
            Icons.switch_account,
            'Switch account',
            '',
            onTap: () => showWtvaSnack(context, 'Sign out and log in with another account', icon: Icons.switch_account),
          ),
          _Tile(
            Icons.people_outline,
            'Other accounts',
            '',
            onTap: () => showWtvaSnack(context, 'Linked accounts: demo only', icon: Icons.people_outline),
          ),
        ],
      ),
    );
  }
}

class PromoterAddLocationScreen extends StatefulWidget {
  const PromoterAddLocationScreen({super.key});

  @override
  State<PromoterAddLocationScreen> createState() => _PromoterAddLocationScreenState();
}

class _PromoterAddLocationScreenState extends State<PromoterAddLocationScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Add location', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Venue name')),
            const SizedBox(height: 16),
            TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
            const Spacer(),
            WtvaGradientButton(
              label: 'Preview',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PromoterPreviewScreen(
                      name: _name.text.isEmpty ? 'New Venue' : _name.text,
                      address: _address.text,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PromoterPreviewScreen extends StatelessWidget {
  final String name;
  final String address;

  const PromoterPreviewScreen({super.key, required this.name, required this.address});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Preview', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://images.unsplash.com/photo-1571266028245-e68f8574baca?w=800&q=80',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(address, style: const TextStyle(color: WtvaColors.neutral300)),
            const Spacer(),
            WtvaGradientButton(
              label: 'Publish promotion',
              onPressed: () {
                Navigator.popUntil(context, (r) => r.isFirst);
                showWtvaSnack(context, 'Location added', icon: Icons.check_circle_outline);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _Tile(this.icon, this.title, this.subtitle, {this.onTap});

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
        subtitle: subtitle.isEmpty ? null : Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
        onTap: onTap,
      ),
    );
  }
}
