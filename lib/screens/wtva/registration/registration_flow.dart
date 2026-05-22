import 'package:flutter/material.dart';
import '../../../config/dev_auth_config.dart';
import '../../../models/user_role.dart';
import '../../../utils/auth_errors.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../theme/figma_theme.dart';
import '../../../widgets/wtva/wtva_auth_shell.dart';
import '../app_shell.dart';
import '../wtva_login_screen.dart';
import '../wtva_terms_screen.dart';
import 'registration_data.dart';

/// Multi-step registration aligned with Figma flow (02_01 → profile → terms → permissions).
class RegistrationFlow extends StatefulWidget {
  const RegistrationFlow({super.key});

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  final _data = RegistrationData();
  final _authService = AuthService();
  final _userService = UserService();

  int _step = 0;
  bool _loading = false;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const _categoryOptions = [
    'Bars',
    'Night clubs',
    'Restaurants',
    'Live music',
    'Lounges',
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    setState(() {
      _error = null;
      _step++;
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _step--);
  }

  void _skipOptionalStep() {
    setState(() {
      _error = null;
      _step++;
    });
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        final email = _emailCtrl.text.trim();
        if (!email.contains('@')) {
          _error = 'Enter a valid email';
          return false;
        }
        _data.email = email;
        _data.rememberSignIn = true;
        return true;
      case 1:
        if (_passwordCtrl.text.length < 6) {
          _error = 'Password must be at least 6 characters';
          return false;
        }
        if (_passwordCtrl.text != _confirmCtrl.text) {
          _error = 'Passwords do not match';
          return false;
        }
        _data.password = _passwordCtrl.text;
        _data.name = _nameCtrl.text.trim().isEmpty ? emailLocalPart(_data.email) : _nameCtrl.text.trim();
        return true;
      case 2:
        if (!_data.acceptedTerms) {
          _error = 'Please accept the terms to continue';
          return false;
        }
        return true;
      case 3:
        return true;
      case 4:
        _data.username = _usernameCtrl.text.trim().isEmpty ? _data.name : _usernameCtrl.text.trim();
        return true;
      case 5:
        return true;
      case 6:
        if (_data.favoriteCategories.isEmpty) {
          _error = 'Pick at least one category';
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  String emailLocalPart(String email) => email.split('@').first;

  Future<void> _onPrimaryAction() async {
    if (!_validateCurrentStep()) {
      setState(() {});
      return;
    }

    if (_step < 6) {
      if (_step == 3) _data.locationEnabled = true;
      if (_step == 5) _data.notificationsEnabled = true;
      _next();
      return;
    }

    await _completeRegistration();
  }

  Future<void> _completeRegistration() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (DevAuthConfig.useDummyAuth) {
        final ok = _userService.registerDummy(
          email: _data.email,
          password: _data.password,
          name: _data.name,
        );
        if (!ok) {
          setState(() {
            _error = 'Could not create demo account';
            _loading = false;
          });
          return;
        }
      } else {
        final response = await _authService.signUp(
          email: _data.email,
          password: _data.password,
          name: _data.name,
          role: UserRole.customer,
        );
        if (response.user == null) {
          setState(() {
            _error = 'Sign up failed';
            _loading = false;
          });
          return;
        }
        if (response.session == null) {
          setState(() {
            _error =
                'Account created! Check your email to confirm, then log in with your password.';
            _loading = false;
          });
          return;
        }
        final synced = await _userService.syncFromAuth(
          fallbackName: _data.name,
          fallbackEmail: _data.email,
        );
        if (!synced) {
          setState(() {
            _error = 'Account created but sign-in did not complete. Try logging in.';
            _loading = false;
          });
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyAuthError(e);
          _loading = false;
        });
      }
    }
  }

  String get _buttonLabel {
    switch (_step) {
      case 0:
        return 'Get Started';
      case 1:
        return 'Continue';
      case 2:
        return 'Accept & continue';
      case 3:
      case 4:
        return 'Continue';
      case 5:
        return 'Enable notifications';
      case 6:
        return 'Finish';
      default:
        return 'Continue';
    }
  }

  bool get _buttonEnabled {
    switch (_step) {
      case 0:
        return _emailCtrl.text.trim().contains('@');
      case 1:
        return _passwordCtrl.text.isNotEmpty && _confirmCtrl.text.isNotEmpty;
      case 2:
        return _data.acceptedTerms;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WtvaAuthShell(
      showBack: _step > 0,
      onBack: _back,
      onClose: () => Navigator.maybePop(context),
      bottomButtonLabel: _buttonLabel,
      bottomEnabled: _buttonEnabled,
      bottomLoading: _loading,
      onBottomPressed: _onPrimaryAction,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          _buildStepContent(context),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: WtvaColors.accentPink)),
          ],
          if (_step == 3 || _step == 5) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _skipOptionalStep,
              child: Text(
                _step == 3 ? 'Not now' : 'Skip for now',
                style: const TextStyle(color: WtvaColors.neutral300),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_step) {
      case 0:
        return _emailStep(context);
      case 1:
        return _passwordStep(context);
      case 2:
        return _termsStep(context);
      case 3:
        return _locationStep(context);
      case 4:
        return _profileStep(context);
      case 5:
        return _notificationsStep(context);
      case 6:
        return _categoriesStep(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _emailStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'Create an account'),
        const SizedBox(height: 16),
        _linkRow(
          "Have an account? ",
          'Sign In',
          () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WtvaLoginScreen()),
          ),
        ),
        const SizedBox(height: 28),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: WtvaColors.neutral50),
          decoration: const InputDecoration(hintText: 'Email'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Remember sign in details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: WtvaColors.neutral50,
                ),
              ),
            ),
            Switch(
              value: _data.rememberSignIn,
              onChanged: (v) => setState(() => _data.rememberSignIn = v),
              activeThumbColor: WtvaColors.neutral50,
              activeTrackColor: WtvaColors.accentPurpleDeep,
            ),
          ],
        ),
      ],
    );
  }

  Widget _passwordStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'Create a password'),
        const SizedBox(height: 8),
        const Text(
          'Choose a secure password for your account.',
          style: TextStyle(color: WtvaColors.neutral200, fontSize: 14),
        ),
        const SizedBox(height: 28),
        TextFormField(
          controller: _nameCtrl,
          style: const TextStyle(color: WtvaColors.neutral50),
          decoration: const InputDecoration(hintText: 'Full name (optional)'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: WtvaColors.neutral50),
          decoration: InputDecoration(
            hintText: 'Password',
            suffixIcon: _visibilityToggle(_obscurePassword, () {
              setState(() => _obscurePassword = !_obscurePassword);
            }),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: WtvaColors.neutral50),
          decoration: InputDecoration(
            hintText: 'Confirm password',
            suffixIcon: _visibilityToggle(_obscureConfirm, () {
              setState(() => _obscureConfirm = !_obscureConfirm);
            }),
          ),
        ),
      ],
    );
  }

  Widget _termsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'Terms & policies'),
        const SizedBox(height: 16),
        const Text(
          'Please review and accept our terms before continuing.',
          style: TextStyle(color: WtvaColors.neutral200, fontSize: 14),
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WtvaColors.night200),
          ),
          child: const SingleChildScrollView(
            child: Text(
              'By using Where The Vibes At you agree to our Terms of Service and Privacy Policy. '
              'You must be 21+ to use nightlife features. We collect location data to show nearby venues. '
              'Promotional offers are subject to venue availability.',
              style: TextStyle(fontSize: 13, height: 1.5, color: WtvaColors.neutral200),
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _data.acceptedTerms,
          onChanged: (v) => setState(() => _data.acceptedTerms = v ?? false),
          activeColor: WtvaColors.accentPurpleDeep,
          title: const Text('I accept the terms and policies', style: TextStyle(fontSize: 14)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WtvaTermsScreen()),
            );
          },
          child: const Text(
            'Read full terms',
            style: TextStyle(
              color: WtvaColors.lavender300,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationStep(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: WtvaColors.buttonGradient,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(Icons.location_on, size: 56, color: Colors.white),
        ),
        const SizedBox(height: 32),
        _title(context, 'Enable location', center: true),
        const SizedBox(height: 12),
        const Text(
          'See venues and events near you. We only use location while you use the app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: WtvaColors.neutral200, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _profileStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'Create a profile'),
        const SizedBox(height: 8),
        const Text(
          'How should friends find you?',
          style: TextStyle(color: WtvaColors.neutral200, fontSize: 14),
        ),
        const SizedBox(height: 32),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: WtvaColors.dark300,
                child: Text(
                  (_nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: WtvaColors.accentPurple),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: WtvaColors.accentPurpleDeep,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        TextFormField(
          controller: _usernameCtrl,
          style: const TextStyle(color: WtvaColors.neutral50),
          decoration: const InputDecoration(hintText: 'Username'),
        ),
      ],
    );
  }

  Widget _notificationsStep(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: WtvaColors.fabGradient,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(Icons.notifications_active, size: 56, color: Colors.white),
        ),
        const SizedBox(height: 32),
        _title(context, 'Stay in the loop', center: true),
        const SizedBox(height: 12),
        const Text(
          'Get notified about live vibes, check-in invites, and promos at your favorite spots.',
          textAlign: TextAlign.center,
          style: TextStyle(color: WtvaColors.neutral200, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _categoriesStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'What are you into?'),
        const SizedBox(height: 8),
        const Text(
          'Pick a few — we\'ll personalize your Discover feed.',
          style: TextStyle(color: WtvaColors.neutral200, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categoryOptions.map((c) {
            final selected = _data.favoriteCategories.contains(c);
            return FilterChip(
              label: Text(c),
              selected: selected,
              onSelected: (_) {
                setState(() => _data.toggleCategory(c));
              },
              selectedColor: WtvaColors.accentPurple.withValues(alpha: 0.35),
              checkmarkColor: WtvaColors.neutral50,
              labelStyle: TextStyle(
                color: selected ? WtvaColors.neutral50 : WtvaColors.neutral200,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: WtvaColors.dark400,
              side: BorderSide(color: WtvaColors.night200),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _title(BuildContext context, String text, {bool center = false}) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
    );
  }

  Widget _linkRow(String prefix, String link, VoidCallback onTap) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prefix, style: const TextStyle(color: WtvaColors.neutral50)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            link,
            style: const TextStyle(
              color: WtvaColors.lavender300,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _visibilityToggle(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility : Icons.visibility_off,
        color: WtvaColors.neutral300,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}
