class AppNotification {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final IconKind kind;
  final bool unread;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.kind,
    this.unread = false,
  });
}

enum IconKind { invite, rank, checkIn, message, promo }

class MockNotificationsData {
  /// No seeded notifications until push/inbox backend is wired.
  static const List<AppNotification> items = [];
}
