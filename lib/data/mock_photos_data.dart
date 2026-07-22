class GalleryItem {
  final String id;
  final String imageUrl;
  final String venueName;
  final String timeAgo;
  final int likes;
  final bool isVideo;

  const GalleryItem({
    required this.id,
    required this.imageUrl,
    required this.venueName,
    required this.timeAgo,
    this.likes = 0,
    this.isVideo = false,
  });
}

class MockPhotosData {
  /// No seeded gallery — empty until user media is wired.
  static const List<GalleryItem> items = [];
  static const List<GalleryItem> videos = [];
}
