import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import '../../utils/wtva_feedback.dart';
import '../../widgets/wtva/wtva_auth_shell.dart';
/// Business forgot-password flow (demo).
class BusinessForgotPasswordScreen extends StatefulWidget {
  const BusinessForgotPasswordScreen({super.key});

  @override
  State<BusinessForgotPasswordScreen> createState() => _BusinessForgotPasswordScreenState();
}

class _BusinessForgotPasswordScreenState extends State<BusinessForgotPasswordScreen> {
  int _step = 0;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    Navigator.pop(context);
    showWtvaSnack(context, 'Password updated (demo)', icon: Icons.lock_reset);
  }

  @override
  Widget build(BuildContext context) {
    return WtvaAuthShell(
      showBack: _step > 0,
      onBack: () => setState(() => _step--),
      onClose: () => Navigator.pop(context),
      bottomButtonLabel: _step == 0 ? 'Send reset link' : _step == 1 ? 'Continue' : 'Reset password',
      bottomEnabled: _step == 0 ? _email.text.contains('@') : _step == 1 ? true : _password.text.length >= 6 && _password.text == _confirm.text,
      onBottomPressed: _next,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Text(
            _step == 0 ? 'Forgot password' : _step == 1 ? 'Check your email' : 'Reset password',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _step == 0
                ? 'We will send a reset link to your business email.'
                : _step == 1
                    ? 'Tap continue — demo skips real email.'
                    : 'Choose a new password (6+ characters).',
            style: const TextStyle(color: WtvaColors.neutral300),
          ),
          const SizedBox(height: 24),
          if (_step == 0)
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: WtvaColors.neutral50),
              decoration: const InputDecoration(hintText: 'Business email'),
              onChanged: (_) => setState(() {}),
            ),
          if (_step == 1)
            const BusinessCardPlaceholder(
              icon: Icons.mark_email_read_outlined,
              text: 'Reset link sent to your inbox (demo)',
            ),
          if (_step == 2) ...[
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'New password'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Confirm password'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }
}

class BusinessCardPlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;

  const BusinessCardPlaceholder({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: WtvaColors.neutral200),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: WtvaColors.neutral200)),
        ],
      ),
    );
  }
}
