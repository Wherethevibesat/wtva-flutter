import 'package:flutter/material.dart';
import '../../data/mock_photos_data.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/guest_locked_view.dart';
import '../../utils/wtva_media_viewer.dart';

class PhotosHubScreen extends StatefulWidget {
  const PhotosHubScreen({super.key});

  @override
  State<PhotosHubScreen> createState() => _PhotosHubScreenState();
}

class _PhotosHubScreenState extends State<PhotosHubScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    if (UserService().isGuest) {
      return Scaffold(
        backgroundColor: WtvaColors.dark500,
        appBar: AppBar(
          backgroundColor: WtvaColors.dark500,
          title: const Text('Photos & videos', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: const GuestLockedView(
          title: 'Your gallery is for members',
          message: 'Sign up to upload photos and videos from your nights out.',
          icon: Icons.photo_library_outlined,
        ),
      );
    }

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Photos & videos', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _TabChip(label: 'Photos', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                const SizedBox(width: 8),
                _TabChip(label: 'Videos', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: MockPhotosData.items.length,
                    itemBuilder: (context, i) => _PhotoCard(item: MockPhotosData.items[i]),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: MockPhotosData.videos.length,
                    itemBuilder: (context, i) => _PhotoCard(item: MockPhotosData.videos[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? WtvaColors.buttonGradient : null,
          color: selected ? null : WtvaColors.dark400,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : WtvaColors.night200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? WtvaColors.onPrimary : WtvaColors.neutral300,
          ),
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final GalleryItem item;

  const _PhotoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openWtvaMediaViewer(context, item),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(item.imageUrl, fit: BoxFit.cover),
          if (item.isVideo)
            const Center(
              child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white70),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    WtvaColors.dark500.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.venueName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        item.timeAgo,
                        style: const TextStyle(fontSize: 10, color: WtvaColors.neutral300),
                      ),
                      const Spacer(),
                      const Icon(Icons.favorite, size: 12, color: WtvaColors.accentPink),
                      const SizedBox(width: 4),
                      Text('${item.likes}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
