import 'package:flutter/material.dart';
import '../../config/dev_auth_config.dart';
import '../../utils/auth_errors.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../navigation/mode_navigation.dart';
import '../../widgets/wtva/wtva_auth_shell.dart';
import 'app_shell.dart';
import 'registration/registration_flow.dart';
import 'wtva_forgot_password_screen.dart';

class WtvaLoginScreen extends StatefulWidget {
  const WtvaLoginScreen({super.key});

  @override
  State<WtvaLoginScreen> createState() => _WtvaLoginScreenState();
}

class _WtvaLoginScreenState extends State<WtvaLoginScreen> {
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
      _emailController.text = 'customer@demo.com';
      _passwordController.text = DevAuthConfig.dummyPassword;
    } else {
      _emailController.text = '';
      _passwordController.text = '';
    }
    _emailController.addListener(_onFieldsChanged);
    _passwordController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() => setState(() {});

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
                'Invalid login. Use a demo account or register with any email (password 6+ chars).';
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
        final synced = await _userService.syncFromAuth(
          fallbackEmail: _emailController.text.trim(),
        );
        if (!synced) {
          setState(() {
            _errorMessage = 'Sign in failed to load your profile. Try again.';
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = friendlyAuthError(e);
        _isLoading = false;
      });
    }
  }

  void _guestLogin() {
    _userService.continueAsGuest();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
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
      bottomLinkLabel: 'Continue as a guest',
      onBottomLinkPressed: _guestLogin,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Text(
              'Log in',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistrationFlow()),
                  ),
                  child: const Text(
                    'Registration',
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
                  color: WtvaColors.accentPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WtvaColors.accentPurple.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Dev: customer@demo.com — password: password. '
                  'Or register any email with a 6+ character password.',
                  style: TextStyle(fontSize: 12, color: WtvaColors.neutral200),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: WtvaColors.accentPink)),
            ],
            const SizedBox(height: 28),
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
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WtvaForgotPasswordScreen()),
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
          ],
        ),
      ),
    );
  }
}
