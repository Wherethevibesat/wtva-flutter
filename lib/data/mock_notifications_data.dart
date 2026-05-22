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
  static const items = [
    AppNotification(
      id: '1',
      title: 'Venue invite',
      body: 'Joe\'s Strip Bar invited you to check in — earn +50 points',
      timeAgo: '10m ago',
      kind: IconKind.invite,
      unread: true,
    ),
    AppNotification(
      id: '2',
      title: 'Rank progress',
      body: 'You\'re 3,028 points from Vibe Champion',
      timeAgo: '2h ago',
      kind: IconKind.rank,
      unread: true,
    ),
    AppNotification(
      id: '3',
      title: 'Lex Night checked in',
      body: 'Dream Land · "Pull up, vibes are insane"',
      timeAgo: '4h ago',
      kind: IconKind.checkIn,
    ),
    AppNotification(
      id: '4',
      title: 'New message',
      body: 'Sasha Go: Nice post at the lounge 🔥',
      timeAgo: 'Yesterday',
      kind: IconKind.message,
    ),
    AppNotification(
      id: '5',
      title: 'Promoted spot',
      body: '2-for-1 drinks at Post Oak Lounge this Friday',
      timeAgo: '2d ago',
      kind: IconKind.promo,
    ),
  ];
}
