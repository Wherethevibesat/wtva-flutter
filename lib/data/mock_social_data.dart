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
  static const avatar =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&q=80';

  static const currentUser = SocialUser(
    id: 'me',
    name: 'John Doe',
    username: 'johndoe',
    avatarUrl: avatar,
    followers: 248,
    following: 186,
    points: 14972,
    rank: 'Vibe Master',
  );

  static const users = [
    SocialUser(
      id: 'lex',
      name: 'Lex Night',
      username: 'lexnight',
      avatarUrl: avatar,
      followers: 1200,
      following: 340,
      points: 14200,
      rank: 'Vibe Master',
      followsYou: true,
    ),
    SocialUser(
      id: 'sasha',
      name: 'Sasha Go',
      username: 'sashago',
      avatarUrl: avatar,
      followers: 890,
      following: 210,
      points: 12880,
      followsYou: true,
    ),
    SocialUser(
      id: 'nova',
      name: 'Nova Vibes',
      username: 'novavibes',
      avatarUrl: avatar,
      followers: 5200,
      following: 890,
      points: 48210,
      rank: 'Influencers',
    ),
  ];

  static List<ChatMessage> messagesFor(String threadId) {
    if (threadId == '1') {
      return const [
        ChatMessage(id: '1', text: 'Hey! We have a special tonight — 50% off entry.', isMe: false, time: '8:30 PM', isVenue: true),
        ChatMessage(id: '2', text: 'Sounds good, I\'ll check in around 10', isMe: true, time: '8:32 PM'),
        ChatMessage(id: '3', text: 'You\'re invited to check in tonight — earn +50 points', isMe: false, time: '9:01 PM', isVenue: true),
      ];
    }
    return const [
      ChatMessage(id: '1', text: 'We\'re at Dream Land, come through!', isMe: false, time: '7:15 PM'),
      ChatMessage(id: '2', text: 'On my way 🔥', isMe: true, time: '7:18 PM'),
      ChatMessage(id: '3', text: 'Door is on the left side', isMe: false, time: '7:20 PM'),
    ];
  }

  static const requests = [
    ChatRequest(id: 'r1', name: 'Miles Out', avatarUrl: avatar, preview: 'Wants to follow you'),
    ChatRequest(id: 'r2', name: 'Post Oak Lounge', preview: 'Venue invite to check in', isBusiness: true),
    ChatRequest(id: 'r3', name: 'Cam Hot', avatarUrl: avatar, preview: 'Sent you a message request'),
  ];

  static final followers = [users[0], users[1], users[2]];
  static final following = [users[0], users[1]];
}
