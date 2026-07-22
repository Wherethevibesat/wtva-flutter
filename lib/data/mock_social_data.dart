class SocialUser {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final int followers;
  final int following;
  final int points;
  final String rank;
  final bool followsYou;

  const SocialUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.followers = 0,
    this.following = 0,
    this.points = 0,
    this.rank = 'Vibee',
    this.followsYou = false,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final bool isVenue;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.isVenue = false,
  });
}

class ChatRequest {
  final String id;
  final String name;
  final String? avatarUrl;
  final String preview;
  final bool isBusiness;

  const ChatRequest({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.preview,
    this.isBusiness = false,
  });
}

class MockSocialData {
  /// No demo users / threads until social is wired.
  static const List<SocialUser> users = [];
  static const List<ChatRequest> requests = [];
  static const List<SocialUser> followers = [];
  static const List<SocialUser> following = [];

  static List<ChatMessage> messagesFor(String threadId) => const [];
}
