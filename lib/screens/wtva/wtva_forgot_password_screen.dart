import 'package:flutter/material.dart';
import '../../config/dev_auth_config.dart';
import '../../services/auth_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_auth_shell.dart';

class WtvaForgotPasswordScreen extends StatefulWidget {
  const WtvaForgotPasswordScreen({super.key});

  @override
  State<WtvaForgotPasswordScreen> createState() => _WtvaForgotPasswordScreenState();
}

class _WtvaForgotPasswordScreenState extends State<WtvaForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _sent = false;
  String? _error;

  bool get _canSend => _emailController.text.trim().contains('@');

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (DevAuthConfig.useDummyAuth) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      } else {
        await _authService.resetPassword(_emailController.text.trim());
      }
      if (mounted) {
        setState(() {
          _sent = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WtvaAuthShell(
      showBack: true,
      onClose: () => Navigator.maybePop(context),
      bottomButtonLabel: _sent ? 'Back to log in' : 'Send verification link',
      bottomEnabled: _sent || _canSend,
      bottomLoading: _loading,
      onBottomPressed: _sent ? () => Navigator.pop(context) : _submit,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Text(
              'Forgot password',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _sent
                  ? 'We sent a verification link to your email. Open it to reset your password.'
                  : 'You can reset your password via your registered email. A verification link will be sent to your email address.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: WtvaColors.neutral200,
              ),
            ),
            if (DevAuthConfig.useDummyAuth && !_sent) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WtvaColors.accentPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Dev mode: any valid email will show the success state.',
                  style: TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: WtvaColors.accentPink)),
            ],
            if (_sent) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WtvaColors.accentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WtvaColors.accentGreen.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, color: WtvaColors.accentGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _emailController.text.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: WtvaColors.neutral50,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: WtvaColors.neutral50),
                decoration: const InputDecoration(hintText: 'Email'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
