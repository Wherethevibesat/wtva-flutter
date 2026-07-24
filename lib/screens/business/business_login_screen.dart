import 'package:flutter/material.dart';
import '../../config/dev_auth_config.dart';
import '../../models/app_mode.dart';
import '../../navigation/mode_navigation.dart';
import '../../utils/auth_errors.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_auth_shell.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';
import 'business_forgot_password_screen.dart';
import 'business_registration_flow.dart';
import 'business_shell.dart';

class BusinessLoginScreen extends StatefulWidget {
  const BusinessLoginScreen({super.key});

  @override
  State<BusinessLoginScreen> createState() => _BusinessLoginScreenState();
}

class _BusinessLoginScreenState extends State<BusinessLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (DevAuthConfig.useDummyAuth) {
      _emailController.text = 'business@demo.com';
      _passwordController.text = DevAuthConfig.dummyPassword;
    } else {
      _emailController.text = '';
      _passwordController.text = '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (DevAuthConfig.useDummyAuth) {
        final ok = _userService.tryDummyLogin(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!ok) {
          setState(() {
            _errorMessage =
                'Use business@demo.com or owner@demo.com (password: password), or register any business email.';
            _isLoading = false;
          });
          return;
        }
      } else {
        final response = await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (response.user == null) {
          setState(() {
            _errorMessage = 'Sign in failed';
            _isLoading = false;
          });
          return;
        }
        await _userService.initializeUser();
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BusinessShell()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = friendlyAuthError(e);
        _isLoading = false;
      });
    }
  }

  void _demoLogin() {
    _userService.loginAs(UserService.mockVenueOwner, dummy: true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BusinessShell()),
    );
  }

  InputDecoration _fieldDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: WtvaColors.dark400,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      suffixIcon: suffix,
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
    return WtvaAuthShell(
      onClose: () => ModeNavigation.openModePicker(context),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            Text(
              'Business log in',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -0.6,
                    color: WtvaColors.neutral50,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Don't have a business account? ",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: WtvaColors.neutral200,
                        fontSize: 15,
                      ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusinessRegistrationFlow()),
                  ),
                  child: const Text(
                    'Create account',
                    style: TextStyle(
                      color: WtvaColors.accentPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (DevAuthConfig.useDummyAuth) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      WtvaColors.accentPurple.withValues(alpha: 0.08),
                      WtvaColors.accentPink.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: WtvaColors.accentPurple.withValues(alpha: 0.18),
                  ),
                ),
                child: const Text(
                  'Dev: business@demo.com · owner@demo.com — password: password. '
                  'Or register any email with a 6+ character password.',
                  style: TextStyle(fontSize: 12, color: WtvaColors.neutral200, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: WtvaColors.accentPink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 28),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                color: WtvaColors.neutral50,
                fontWeight: FontWeight.w600,
              ),
              decoration: _fieldDecoration('Business email'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(
                color: WtvaColors.neutral50,
                fontWeight: FontWeight.w600,
              ),
              decoration: _fieldDecoration(
                'Password',
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: WtvaColors.neutral300,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BusinessForgotPasswordScreen()),
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: WtvaColors.accentPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            WtvaGradientButton(
              label: 'Log in',
              onPressed: _handleLogin,
              loading: _isLoading,
            ),
            if (DevAuthConfig.useDummyAuth) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(child: Divider(color: WtvaColors.night200)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: WtvaColors.neutral300,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: WtvaColors.night200)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _demoLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WtvaColors.accentPurple,
                    backgroundColor: WtvaColors.dark400,
                    side: const BorderSide(color: WtvaColors.accentPurple, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Continue with demo business'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => ModeNavigation.switchToMode(context, AppMode.customer),
                icon: const Icon(Icons.nightlife_outlined, size: 20),
                label: const Text('Back to customer login'),
                style: TextButton.styleFrom(
                  foregroundColor: WtvaColors.neutral50,
                  backgroundColor: WtvaColors.dark300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: const BorderSide(color: WtvaColors.night200),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
