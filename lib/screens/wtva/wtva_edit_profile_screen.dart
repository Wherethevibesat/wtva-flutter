import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/dev_auth_config.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/wtva_feedback.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';

class WtvaEditProfileScreen extends StatefulWidget {
  const WtvaEditProfileScreen({super.key});

  @override
  State<WtvaEditProfileScreen> createState() => _WtvaEditProfileScreenState();
}

class _WtvaEditProfileScreenState extends State<WtvaEditProfileScreen> {
  late final TextEditingController _nameController;
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = UserService().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showWtvaSnack(context, 'Enter a display name');
      return;
    }

    setState(() => _saving = true);
    try {
      final user = UserService().currentUser;
      if (user != null &&
          !DevAuthConfig.useDummyAuth &&
          user.id != 'guest' &&
          !user.id.startsWith('demo-')) {
        await AuthService().updateUserProfile(userId: user.id, name: name);
      }
      UserService().updateDisplayName(name);
      if (!mounted) return;
      Navigator.pop(context);
      showWtvaSnack(context, 'Profile updated', icon: Icons.check_circle_outline);
    } catch (e) {
      if (!mounted) return;
      showWtvaSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null && mounted) {
      showWtvaSnack(
        context,
        'Photo upload is coming soon — your name still saves.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService().currentUser;
    final email = user?.email ?? '';
    final avatar = user?.profileImageUrl;

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: WtvaColors.dark300,
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null
                      ? Text(
                          (_nameController.text.isNotEmpty ? _nameController.text[0] : '?')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: WtvaColors.neutral50,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _changePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: WtvaColors.neutral50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: WtvaColors.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: WtvaColors.neutral50),
            decoration: const InputDecoration(labelText: 'Display name'),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: email),
            style: const TextStyle(color: WtvaColors.neutral300),
            decoration: const InputDecoration(
              labelText: 'Email',
              helperText: 'Change email from Settings → Change email',
            ),
          ),
          const SizedBox(height: 32),
          WtvaGradientButton(label: 'Save changes', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
