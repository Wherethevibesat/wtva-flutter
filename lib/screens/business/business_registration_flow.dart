import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../config/dev_auth_config.dart';
import '../../models/business/business_models.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/business_repository.dart';
import '../../services/business_service.dart';
import '../../services/business_verification_service.dart';
import '../../services/supabase_data.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/neighborhood_dropdown.dart';
import '../../widgets/wtva/wtva_auth_shell.dart';
import 'business_shell.dart';
import 'business_subscription_screen.dart';

/// Full business onboarding (#02): account → business → verify → profile → plan.
class BusinessRegistrationFlow extends StatefulWidget {
  const BusinessRegistrationFlow({super.key});

  @override
  State<BusinessRegistrationFlow> createState() => _BusinessRegistrationFlowState();
}

class _BusinessRegistrationFlowState extends State<BusinessRegistrationFlow> {
  int _step = 0;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _venue = TextEditingController();
  final _address = TextEditingController();
  String? _neighborhood;
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _categories = <String>{'Bars', 'Night clubs'};
  final _services = <String>{'VIP tables', 'Bottle service'};
  bool _terms = false;
  PlatformFile? _verificationFile;
  String? _verificationError;
  bool _uploadingDoc = false;
  BusinessSubscriptionTier _tier = BusinessSubscriptionTier.gold;

  static const _allCategories = ['Bars', 'Night clubs', 'Restaurants', 'Live music', 'Lounges'];
  static const _allServices = ['VIP tables', 'Bottle service', 'Live DJ', 'Outdoor patio', 'Private events'];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _venue.dispose();
    _address.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  int get _totalSteps => 9;

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      return;
    }
    _finish();
  }

  void _back() {
    if (_step == 0) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _step--);
  }

  Future<void> _finish() async {
    final profile = BusinessVenueProfile(
      venueName: _venue.text.trim().isEmpty ? 'My Venue' : _venue.text.trim(),
      address: _address.text.trim(),
      neighborhood: _neighborhood ?? '',
      phone: _phone.text.trim(),
      description: _bio.text.trim(),
      categories: _categories.toList(),
      serviceOptions: _services.toList(),
      tier: _tier,
      verified: false,
      verificationStatus: _verificationFile != null ? 'pending' : 'none',
    );

    if (SupabaseData.syncAuth) {
      final auth = AuthService();
      final email = _email.text.trim();
      final password = _password.text;
      try {
        final existing = UserService().isLoggedIn;
        if (!existing) {
          final response = await auth.signUp(
            email: email,
            password: password,
            name: profile.venueName,
            role: UserRole.venueOwner,
          );
          if (response.user == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign up failed. Please try again.')),
            );
            return;
          }
          if (response.session == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Account created. Confirm your email, then log in to finish setup.',
                ),
              ),
            );
            return;
          }
        }
        final synced = await UserService().syncFromAuth(
          fallbackName: profile.venueName,
          fallbackEmail: email,
        );
        if (!synced) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not sign you in. Try logging in.')),
          );
          return;
        }
        final ownerId = UserService().currentUser?.id;
        if (ownerId != null) {
          if (_verificationFile != null) {
            setState(() => _uploadingDoc = true);
            final docPath = await BusinessVerificationService.instance.uploadForOwner(
              ownerId: ownerId,
              file: _verificationFile!,
            );
            if (docPath != null) {
              profile.verificationDocumentPath = docPath;
              profile.verificationStatus = 'pending';
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document upload failed. Try again from settings.')),
              );
            }
            if (mounted) setState(() => _uploadingDoc = false);
          }
          final venueId = await BusinessRepository.instance.createVenueForOwner(
            profile: profile,
            ownerId: ownerId,
          );
          if (venueId != null) {
            await BusinessRepository.instance.saveVenueProfile(profile, venueId: venueId);
          }
          await BusinessService.instance.updateProfile(profile);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
        return;
      }
    } else if (DevAuthConfig.useDummyAuth) {
      UserService().registerDummy(
        email: _email.text.trim(),
        password: _password.text,
        name: _venue.text.trim(),
        role: UserRole.venueOwner,
      );
      await BusinessService.instance.updateProfile(profile);
    }

    await BusinessService.instance.markRegistrationComplete();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BusinessShell()),
      (_) => false,
    );
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _email.text.contains('@');
      case 1:
        return _password.text.length >= 6 && _password.text == _confirm.text;
      case 2:
        return _venue.text.trim().isNotEmpty && (_neighborhood?.isNotEmpty ?? false);
      case 3:
        return _verificationFile != null && !_uploadingDoc;
      case 4:
        return _categories.isNotEmpty;
      case 5:
        return true;
      case 6:
        return _services.isNotEmpty;
      case 7:
        return true;
      case 8:
        return _terms;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 7) {
      return BusinessSubscriptionScreen(
        selected: _tier,
        onSelect: (t) => setState(() => _tier = t),
        onContinue: _next,
        onBack: _back,
      );
    }

    return WtvaAuthShell(
      showBack: true,
      onBack: _back,
      onClose: () => Navigator.maybePop(context),
      bottomButtonLabel: _step == _totalSteps - 1 ? 'Create business account' : 'Continue',
      bottomEnabled: _canContinue && !_uploadingDoc,
      bottomLoading: _uploadingDoc,
      onBottomPressed: _uploadingDoc ? null : _next,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Text(_title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Step ${_step + 1} of $_totalSteps',
            style: const TextStyle(color: WtvaColors.neutral300, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(_subtitle, style: const TextStyle(color: WtvaColors.neutral300)),
          const SizedBox(height: 24),
          ..._fields,
        ],
      ),
    );
  }

  String get _title {
    const titles = [
      'Create account',
      'Create password',
      'Add your business',
      'Verify business',
      'Categories',
      'Business profile',
      'Service options',
      'Choose plan',
      'Terms & policies',
    ];
    return titles[_step.clamp(0, titles.length - 1)];
  }

  String get _subtitle {
    const subs = [
      'Business email for your portal.',
      'Secure your account.',
      'Name and location of your venue.',
      'Confirm you represent this business.',
      'Help guests find you.',
      'Description and contact.',
      'What you offer tonight.',
      'Silver, Gold, or Platinum.',
      'Review and accept to finish.',
    ];
    return subs[_step.clamp(0, subs.length - 1)];
  }

  List<Widget> get _fields {
    switch (_step) {
      case 0:
        return [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Business email'),
            onChanged: (_) => setState(() {}),
          ),
        ];
      case 1:
        return [
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Confirm password'),
            onChanged: (_) => setState(() {}),
          ),
        ];
      case 2:
        return [
          TextField(controller: _venue, decoration: const InputDecoration(hintText: 'Venue name'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          NeighborhoodDropdown(
            value: _neighborhood,
            onChanged: (value) => setState(() => _neighborhood = value),
          ),
          const SizedBox(height: 16),
          TextField(controller: _address, decoration: const InputDecoration(hintText: 'Address'), onChanged: (_) => setState(() {})),
        ];
      case 3:
        return [
          const Text(
            'Upload your business license or EIN letter (PDF or image).',
            style: TextStyle(color: WtvaColors.neutral200, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _uploadingDoc ? null : () async {
              final file = await BusinessVerificationService.instance.pickDocument();
              if (!mounted) return;
              setState(() {
                _verificationFile = file;
                _verificationError = file == null ? 'No file selected' : null;
              });
            },
            icon: const Icon(Icons.upload_file),
            label: Text(_verificationFile == null ? 'Choose file' : 'Change file'),
            style: OutlinedButton.styleFrom(
              foregroundColor: WtvaColors.neutral100,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _uploadingDoc ? null : () async {
              final file = await BusinessVerificationService.instance.pickPhoto();
              if (!mounted) return;
              setState(() {
                _verificationFile = file;
                _verificationError = file == null ? 'No photo selected' : null;
              });
            },
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose photo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: WtvaColors.neutral100,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          if (_verificationFile != null) ...[
            const SizedBox(height: 12),
            Text(
              'Selected: ${_verificationFile!.name}',
              style: const TextStyle(fontSize: 13, color: WtvaColors.accentGreen),
            ),
            const SizedBox(height: 6),
            const Text(
              'We will upload this securely when you finish registration. Review usually takes 1–2 business days.',
              style: TextStyle(fontSize: 12, color: WtvaColors.neutral300, height: 1.35),
            ),
          ],
          if (_verificationError != null) ...[
            const SizedBox(height: 8),
            Text(_verificationError!, style: const TextStyle(color: WtvaColors.accentPink, fontSize: 12)),
          ],
        ];
      case 4:
        return [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allCategories.map((c) {
              final on = _categories.contains(c);
              return FilterChip(
                label: Text(c),
                selected: on,
                onSelected: (v) => setState(() => v ? _categories.add(c) : _categories.remove(c)),
                selectedColor: WtvaColors.neutral50,
                checkmarkColor: WtvaColors.onPrimary,
              );
            }).toList(),
          ),
        ];
      case 5:
        return [
          TextField(controller: _phone, decoration: const InputDecoration(hintText: 'Phone'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          TextField(controller: _bio, maxLines: 3, decoration: const InputDecoration(hintText: 'About your venue'), onChanged: (_) => setState(() {})),
        ];
      case 6:
        return [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allServices.map((s) {
              final on = _services.contains(s);
              return FilterChip(
                label: Text(s),
                selected: on,
                onSelected: (v) => setState(() => v ? _services.add(s) : _services.remove(s)),
                selectedColor: WtvaColors.neutral50,
                checkmarkColor: WtvaColors.onPrimary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Photos & video — add later from settings.', style: TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
        ];
      case 8:
        return [
          CheckboxListTile(
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            title: const Text('I accept Terms & Privacy Policy', style: TextStyle(fontSize: 14)),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: WtvaColors.neutral50,
          ),
        ];
      default:
        return [];
    }
  }
}
