import 'package:flutter/material.dart';
import '../../../data/mock_social_data.dart';
import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';
import 'chat_conversation_screen.dart';
import '../../../data/mock_messages_data.dart';

class ChatRequestsScreen extends StatelessWidget {
  const ChatRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Requests', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: MockSocialData.requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final r = MockSocialData.requests[i];
          return Material(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: WtvaColors.dark300,
                    backgroundImage: r.avatarUrl != null ? NetworkImage(r.avatarUrl!) : null,
                    child: r.avatarUrl == null
                        ? Icon(r.isBusiness ? Icons.storefront : Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(r.preview, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showWtvaSnack(context, 'Declined ${r.name}', icon: Icons.close);
                    },
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatConversationScreen(
                            thread: ChatThread(
                              id: r.id,
                              name: r.name,
                              lastMessage: r.preview,
                              timeAgo: 'Now',
                              avatarUrl: r.avatarUrl,
                              isVenue: r.isBusiness,
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
