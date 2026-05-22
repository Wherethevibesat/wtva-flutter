class ChatThread {
  final String id;
  final String name;
  final String lastMessage;
  final String timeAgo;
  final int unread;
  final String? avatarUrl;
  final bool isVenue;

  const ChatThread({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timeAgo,
    this.unread = 0,
    this.avatarUrl,
    this.isVenue = false,
  });
}

class MockMessagesData {
  static const avatar =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&q=80';

  static const threads = [
    ChatThread(
      id: '1',
      name: 'Joe\'s Strip Bar',
      lastMessage: 'You\'re invited to check in tonight — +50 pts',
      timeAgo: '2m',
      unread: 1,
      isVenue: true,
    ),
    ChatThread(
      id: '2',
      name: 'Lex Night',
      lastMessage: 'We\'re at Dream Land, come through!',
      timeAgo: '18m',
      unread: 2,
      avatarUrl: avatar,
    ),
    ChatThread(
      id: '3',
      name: 'Sasha Go',
      lastMessage: 'Nice post at the lounge 🔥',
      timeAgo: '1h',
      avatarUrl: avatar,
    ),
    ChatThread(
      id: '4',
      name: 'Post Oak Lounge',
      lastMessage: 'Thanks for checking in last weekend',
      timeAgo: 'Yesterday',
      isVenue: true,
    ),
  ];
}
