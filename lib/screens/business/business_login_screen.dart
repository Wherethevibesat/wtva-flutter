import 'package:flutter/material.dart';
import '../../config/dev_auth_config.dart';
import '../../navigation/mode_navigation.dart';
import '../../utils/auth_errors.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_auth_shell.dart';
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

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

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
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
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

  @override
  Widget build(BuildContext context) {
    return WtvaAuthShell(
      onClose: () => ModeNavigation.openModePicker(context),
      bottomButtonLabel: 'Log in',
      bottomEnabled: _canSubmit,
      bottomLoading: _isLoading,
      onBottomPressed: _handleLogin,
      bottomLinkLabel: 'Continue with demo business',
      onBottomLinkPressed: _demoLogin,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Text(
              'Business log in',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage venues, promotions, and bookings.',
              style: TextStyle(color: WtvaColors.neutral300, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Don't have a business account? ",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusinessRegistrationFlow()),
                  ),
                  child: const Text(
                    'Create account',
                    style: TextStyle(
                      color: WtvaColors.lavender300,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            if (DevAuthConfig.useDummyAuth) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: WtvaColors.night200.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WtvaColors.night200),
                ),
                child: const Text(
                  'Dev: business@demo.com · owner@demo.com — password: password. '
                  'Or register any email with 6+ characters.',
                  style: TextStyle(fontSize: 12, color: WtvaColors.neutral200),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: WtvaColors.accentPink)),
            ],
            const SizedBox(height: 12),
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
                    color: WtvaColors.lavender300,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: WtvaColors.neutral50),
              decoration: const InputDecoration(hintText: 'Business email'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: WtvaColors.neutral50),
              decoration: InputDecoration(
                hintText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
          ],
        ),
      ),
    );
  }
}
