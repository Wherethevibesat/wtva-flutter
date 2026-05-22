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
  static const items = [
    GalleryItem(
      id: '1',
      imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&q=80',
      venueName: 'Joe\'s Strip Bar',
      timeAgo: '2h ago',
      likes: 42,
    ),
    GalleryItem(
      id: '2',
      imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&q=80',
      venueName: 'Dream Land',
      timeAgo: '5h ago',
      likes: 18,
    ),
    GalleryItem(
      id: '3',
      imageUrl: 'https://images.unsplash.com/photo-1571266028245-e4733b9ebbd0?w=400&q=80',
      venueName: 'Post Oak Lounge',
      timeAgo: 'Yesterday',
      likes: 91,
    ),
    GalleryItem(
      id: '4',
      imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&q=80',
      venueName: 'The Velvet Room',
      timeAgo: '2d ago',
      likes: 33,
    ),
    GalleryItem(
      id: '5',
      imageUrl: 'https://images.unsplash.com/photo-1459749411175-04bf52924e91?w=400&q=80',
      venueName: 'Skyline Rooftop',
      timeAgo: '3d ago',
      likes: 67,
    ),
    GalleryItem(
      id: '6',
      imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400&q=80',
      venueName: 'Neon Alley',
      timeAgo: '1w ago',
      likes: 12,
    ),
  ];

  static const videos = [
    GalleryItem(
      id: 'v1',
      imageUrl: 'https://images.unsplash.com/photo-1571266028245-e4733b9ebbd0?w=600&q=80',
      venueName: 'Dream Land',
      timeAgo: '3h ago',
      likes: 120,
      isVideo: true,
    ),
    GalleryItem(
      id: 'v2',
      imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600&q=80',
      venueName: "Joe's Strip Bar",
      timeAgo: 'Yesterday',
      likes: 88,
      isVideo: true,
    ),
    GalleryItem(
      id: 'v3',
      imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80',
      venueName: 'The Dream Club',
      timeAgo: '2d ago',
      likes: 45,
      isVideo: true,
    ),
  ];
}
