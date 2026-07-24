import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import '../../utils/wtva_feedback.dart';
import '../../widgets/wtva/wtva_auth_shell.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';

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

  bool get _canContinue {
    if (_step == 0) return _email.text.contains('@');
    if (_step == 1) return true;
    return _password.text.length >= 6 && _password.text == _confirm.text;
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    Navigator.pop(context);
    showWtvaSnack(context, 'Password updated (demo)', icon: Icons.lock_reset);
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: WtvaColors.dark400,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: WtvaColors.night200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: WtvaColors.night200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: WtvaColors.accentPurple, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _step == 0
        ? 'Forgot password'
        : _step == 1
            ? 'Check your email'
            : 'Reset password';
    final subtitle = _step == 0
        ? 'We will send a reset link to your business email.'
        : _step == 1
            ? 'Tap continue — demo skips real email.'
            : 'Choose a new password (6+ characters).';
    final cta = _step == 0
        ? 'Send reset link'
        : _step == 1
            ? 'Continue'
            : 'Reset password';

    return WtvaAuthShell(
      showBack: true,
      onBack: _step > 0 ? () => setState(() => _step--) : () => Navigator.pop(context),
      onClose: () => Navigator.pop(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  letterSpacing: -0.6,
                  color: WtvaColors.neutral50,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: WtvaColors.neutral200,
            ),
          ),
          const SizedBox(height: 28),
          if (_step == 0)
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                color: WtvaColors.neutral50,
                fontWeight: FontWeight.w600,
              ),
              decoration: _fieldDecoration('Business email'),
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
              style: const TextStyle(
                color: WtvaColors.neutral50,
                fontWeight: FontWeight.w600,
              ),
              decoration: _fieldDecoration('New password'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirm,
              obscureText: true,
              style: const TextStyle(
                color: WtvaColors.neutral50,
                fontWeight: FontWeight.w600,
              ),
              decoration: _fieldDecoration('Confirm password'),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 28),
          WtvaGradientButton(
            label: cta,
            onPressed: _canContinue ? _next : null,
            enabled: _canContinue,
          ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WtvaColors.night200),
        boxShadow: WtvaColors.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: WtvaColors.accentPurple),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WtvaColors.neutral200,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
