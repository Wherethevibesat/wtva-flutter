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
  /// No seeded inbox threads — empty until messaging is wired.
  static const List<ChatThread> threads = [];
}
