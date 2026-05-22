import 'package:flutter/material.dart';
import '../data/mock_photos_data.dart';
import '../theme/figma_theme.dart';

void openWtvaMediaViewer(BuildContext context, GalleryItem item) {
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => WtvaMediaViewerPage(item: item),
    ),
  );
}

class WtvaMediaViewerPage extends StatelessWidget {
  final GalleryItem item;

  const WtvaMediaViewerPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(item.venueName, style: const TextStyle(fontSize: 16)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            child: Center(
              child: Image.network(item.imageUrl, fit: BoxFit.contain),
            ),
          ),
          if (item.isVideo)
            const Center(
              child: Icon(Icons.play_circle_fill, size: 72, color: Colors.white70),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Row(
              children: [
                Text(item.timeAgo, style: const TextStyle(color: WtvaColors.neutral300)),
                const Spacer(),
                const Icon(Icons.favorite, color: WtvaColors.accentPink, size: 18),
                const SizedBox(width: 6),
                Text('${item.likes}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
