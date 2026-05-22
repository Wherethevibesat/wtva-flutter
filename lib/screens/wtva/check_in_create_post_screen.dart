import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/mock_venue_store.dart';
import '../../utils/ranking_award_feedback.dart';
import '../../utils/wtva_feedback.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';
import 'active_check_in_screen.dart';

class CheckInCreatePostScreen extends StatefulWidget {
  final String venueId;

  const CheckInCreatePostScreen({super.key, required this.venueId});

  @override
  State<CheckInCreatePostScreen> createState() => _CheckInCreatePostScreenState();
}

class _CheckInCreatePostScreenState extends State<CheckInCreatePostScreen> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  final _extraImages = <String>[];
  bool _posting = false;

  Future<void> _addPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _extraImages.add(file.path));
    showWtvaSnack(context, 'Photo added');
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _posting = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveCheckInScreen(
          venueId: widget.venueId,
          fromPost: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = MockVenueStore.byIdOrThrow(widget.venueId);
    final user = UserService().currentUser;
    final userName = user?.name ?? 'You';

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Create Post', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WtvaColors.dark400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          detail.venue.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.venue.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            Text(
                              'Checking in as $userName',
                              style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified, color: WtvaColors.accentPurple, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _captionController,
                  maxLines: 4,
                  style: const TextStyle(color: WtvaColors.neutral50),
                  decoration: const InputDecoration(
                    hintText: 'Share the vibe...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add photos',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _PhotoSlot(icon: Icons.add_a_photo, label: 'Add', onTap: _addPhoto),
                    _PhotoSlot(imageUrl: detail.venue.imageUrl),
                    ..._extraImages.map((p) => _PhotoSlot(filePath: p)),
                    if (_extraImages.isEmpty)
                      _PhotoSlot(imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&q=80'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WtvaColors.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WtvaColors.accentGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.stars, color: WtvaColors.accentGreen, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Earn 25 points when you check in and post',
                          style: TextStyle(fontSize: 13, color: WtvaColors.neutral200),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: WtvaGradientButton(
              label: 'Post check-in',
              loading: _posting,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final String? imageUrl;
  final String? filePath;
  final VoidCallback? onTap;

  const _PhotoSlot({this.icon, this.label, this.imageUrl, this.filePath, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (filePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(filePath!), fit: BoxFit.cover, height: 100, width: double.infinity),
      );
    }
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl!, fit: BoxFit.cover, height: 100),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: WtvaColors.dark400,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: WtvaColors.night200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.add, color: WtvaColors.neutral300),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(label!, style: const TextStyle(fontSize: 11, color: WtvaColors.neutral300)),
            ],
          ],
        ),
      ),
    );
  }
}
