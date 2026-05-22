import 'package:flutter/material.dart';
import '../../../data/mock_venue_store.dart';
import '../../../models/venue_detail.dart';
import '../../../theme/figma_theme.dart';
class VenueAllCheckInsScreen extends StatelessWidget {
  final String venueId;
  const VenueAllCheckInsScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    final detail = MockVenueStore.byIdOrThrow(venueId);
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: Text('Check-ins · ${detail.venue.name}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: detail.recentCheckIns.length + 2,
        itemBuilder: (context, i) {
          final posts = detail.recentCheckIns;
          final post = posts[i % posts.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CheckInTile(
              post: post,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VenuePhotoViewerScreen(
                    imageUrl: post.imageUrl,
                    caption: post.caption,
                    userName: post.userName,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class VenueAllPhotosScreen extends StatelessWidget {
  final String venueId;
  const VenueAllPhotosScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    final detail = MockVenueStore.byIdOrThrow(venueId);
    final urls = [
      detail.venue.imageUrl,
      ...detail.recentCheckIns.map((p) => p.imageUrl),
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&q=80',
    ];
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('All photos', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: urls.length,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VenuePhotoViewerScreen(imageUrl: urls[i]),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(urls[i], fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class VenueAllVideosScreen extends StatelessWidget {
  final String venueId;
  const VenueAllVideosScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    final detail = MockVenueStore.byIdOrThrow(venueId);
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('All videos', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(detail.venue.imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.play_circle_fill, size: 56, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VenuePhotoViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  final String? userName;

  const VenuePhotoViewerScreen({
    super.key,
    required this.imageUrl,
    this.caption,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Column(
        children: [
          Expanded(child: InteractiveViewer(child: Image.network(imageUrl, fit: BoxFit.contain))),
          if (userName != null || caption != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: WtvaColors.dark400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userName != null) Text(userName!, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (caption != null) Text(caption!, style: const TextStyle(color: WtvaColors.neutral200)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class VenueServiceOptionsSheet extends StatelessWidget {
  final List<String> services;

  const VenueServiceOptionsSheet({super.key, required this.services});

  static Future<void> show(BuildContext context, {required List<String> services}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => VenueServiceOptionsSheet(services: services),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...services.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: WtvaColors.accentGreen, size: 20),
                  const SizedBox(width: 10),
                  Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInTile extends StatelessWidget {
  final VenueCheckInPost post;
  final VoidCallback onTap;

  const _CheckInTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(post.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(post.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(post.timeAgo, style: const TextStyle(fontSize: 11, color: WtvaColors.neutral300)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
