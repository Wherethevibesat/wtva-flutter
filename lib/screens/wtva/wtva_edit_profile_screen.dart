import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  late final TextEditingController _bioController;
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = UserService().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: 'Nightlife explorer · HTX');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    UserService().updateDisplayName(_nameController.text);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    showWtvaSnack(context, 'Profile updated', icon: Icons.check_circle_outline);
  }

  Future<void> _changePhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null && mounted) {
      showWtvaSnack(context, 'Profile photo updated (demo)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService().currentUser;
    final email = user?.email ?? '';

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
                  child: Text(
                    (_nameController.text.isNotEmpty ? _nameController.text[0] : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: WtvaColors.neutral50,
                    ),
                  ),
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
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            controller: TextEditingController(text: email),
            style: const TextStyle(color: WtvaColors.neutral300),
            decoration: const InputDecoration(
              labelText: 'Email',
              helperText: 'Email cannot be changed here',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioController,
            maxLines: 3,
            style: const TextStyle(color: WtvaColors.neutral50),
            decoration: const InputDecoration(
              labelText: 'Bio',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 32),
          WtvaGradientButton(label: 'Save changes', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
