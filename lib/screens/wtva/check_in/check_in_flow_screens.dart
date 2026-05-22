import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';
import '../../../widgets/wtva/wtva_gradient_button.dart';
import '../active_check_in_screen.dart';
import '../check_in_share_sheet.dart';

enum CameraMode { photo, video, live }

class CheckInCameraScreen extends StatefulWidget {
  final String venueId;
  final CameraMode mode;

  const CheckInCameraScreen({super.key, required this.venueId, this.mode = CameraMode.photo});

  @override
  State<CheckInCameraScreen> createState() => _CheckInCameraScreenState();
}

class _CheckInCameraScreenState extends State<CheckInCameraScreen> {
  late CameraMode _mode;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
  }

  Future<void> _openShutter() async {
    if (_mode == CameraMode.live) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckInPhotoPreviewScreen(venueId: widget.venueId, mode: _mode),
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: WtvaColors.dark400,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final file = _mode == CameraMode.video
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckInPhotoPreviewScreen(
          venueId: widget.venueId,
          mode: _mode,
          imagePath: file.path,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: WtvaColors.night500),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt, size: 64, color: WtvaColors.neutral300),
                SizedBox(height: 8),
                Text('Camera preview', style: TextStyle(color: WtvaColors.neutral300)),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    if (_mode == CameraMode.live)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WtvaColors.accentPink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('LIVE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ModeChip('Photo', CameraMode.photo, _mode, (m) => setState(() => _mode = m)),
                    const SizedBox(width: 8),
                    _ModeChip('Video', CameraMode.video, _mode, (m) => setState(() => _mode = m)),
                    const SizedBox(width: 8),
                    _ModeChip('Live', CameraMode.live, _mode, (m) => setState(() => _mode = m)),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _openShutter,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _mode == CameraMode.live ? WtvaColors.accentPink : WtvaColors.accentPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final CameraMode value;
  final CameraMode selected;
  final ValueChanged<CameraMode> onSelect;

  const _ModeChip(this.label, this.value, this.selected, this.onSelect);

  @override
  Widget build(BuildContext context) {
    final on = value == selected;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? WtvaColors.accentPurpleDeep : Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: on ? Colors.white : WtvaColors.neutral300)),
      ),
    );
  }
}

class CheckInPhotoPreviewScreen extends StatelessWidget {
  final String venueId;
  final CameraMode mode;
  final String? imagePath;

  const CheckInPhotoPreviewScreen({
    super.key,
    required this.venueId,
    required this.mode,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Column(
        children: [
          Expanded(
            child: imagePath != null
                ? Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity)
                : Image.network(
                    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=80',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CheckInTagPersonScreen(venueId: venueId)),
                  ),
                  child: const Text('Tag people'),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CheckInFiltersScreen(venueId: venueId)),
                  ),
                  child: const Text('Filters'),
                ),
                const Spacer(),
                WtvaGradientButton(
                  label: 'Next',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CheckInWriteReviewScreen(venueId: venueId)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CheckInTagPersonScreen extends StatefulWidget {
  final String venueId;
  const CheckInTagPersonScreen({super.key, required this.venueId});

  @override
  State<CheckInTagPersonScreen> createState() => _CheckInTagPersonScreenState();
}

class _CheckInTagPersonScreenState extends State<CheckInTagPersonScreen> {
  final _names = ['Lex Night', 'Sasha Go', 'Nova Vibes', 'Miles Out'];
  final _selected = <int>{0};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Tag a person', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_selected.isNotEmpty) {
                final tagged = _selected.map((i) => _names[i]).join(', ');
                showWtvaSnack(context, 'Tagged $tagged', icon: Icons.person_add);
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _names.length,
        itemBuilder: (context, i) => CheckboxListTile(
          value: _selected.contains(i),
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selected.add(i);
              } else {
                _selected.remove(i);
              }
            });
          },
          title: Text(_names[i]),
          activeColor: WtvaColors.accentPurple,
        ),
      ),
    );
  }
}

class CheckInFiltersScreen extends StatefulWidget {
  final String venueId;
  const CheckInFiltersScreen({super.key, required this.venueId});

  @override
  State<CheckInFiltersScreen> createState() => _CheckInFiltersScreenState();
}

class _CheckInFiltersScreenState extends State<CheckInFiltersScreen> {
  static const _filters = ['Original', 'Vivid', 'Night', 'Warm', 'Cool'];
  String _selected = 'Night';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Filters', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showWtvaSnack(context, 'Filter: $_selected', icon: Icons.filter);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
      body: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        children: _filters.map((f) {
          final selected = f == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = f),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: WtvaColors.dark400,
                borderRadius: BorderRadius.circular(12),
                border: selected ? Border.all(color: WtvaColors.accentPurple, width: 2) : null,
              ),
              child: Center(child: Text(f, style: const TextStyle(fontWeight: FontWeight.w600))),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CheckInWriteReviewScreen extends StatefulWidget {
  final String venueId;
  const CheckInWriteReviewScreen({super.key, required this.venueId});

  @override
  State<CheckInWriteReviewScreen> createState() => _CheckInWriteReviewScreenState();
}

class _CheckInWriteReviewScreenState extends State<CheckInWriteReviewScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Write your post', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Share the vibe and your review...',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: WtvaGradientButton(
              label: 'Continue',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CheckInSharePostScreen(venueId: widget.venueId)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckInSharePostScreen extends StatelessWidget {
  final String venueId;
  const CheckInSharePostScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Share your post', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Share to', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareIcon(
                  Icons.message,
                  'Message',
                  onTap: () => showWtvaSnack(context, 'Shared to messages (demo)', icon: Icons.send),
                ),
                _ShareIcon(
                  Icons.camera_alt,
                  'Story',
                  onTap: () => showWtvaSnack(context, 'Added to your story (demo)', icon: Icons.auto_stories),
                ),
                _ShareIcon(
                  Icons.public,
                  'Feed',
                  onTap: () => showWtvaSnack(context, 'Posted to feed (demo)', icon: Icons.public),
                ),
                _ShareIcon(
                  Icons.more_horiz,
                  'More',
                  onTap: () => CheckInShareSheet.show(context, venueName: 'this venue'),
                ),
              ],
            ),
            const Spacer(),
            WtvaGradientButton(
              label: 'Post & check in',
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveCheckInScreen(venueId: venueId, fromPost: true),
                  ),
                  (r) => r.isFirst,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareIcon(this.icon, this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: WtvaColors.dark400, shape: BoxShape.circle),
            child: Icon(icon, color: WtvaColors.neutral50),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
