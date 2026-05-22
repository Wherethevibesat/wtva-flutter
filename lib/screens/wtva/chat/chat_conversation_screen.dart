import 'package:flutter/material.dart';
import '../../../data/mock_messages_data.dart';
import '../../../data/mock_social_data.dart';
import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';

class ChatConversationScreen extends StatefulWidget {
  final ChatThread thread;

  const ChatConversationScreen({super.key, required this.thread});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _controller = TextEditingController();
  final _messages = <ChatMessage>[];

  @override
  void initState() {
    super.initState();
    _messages.addAll(MockSocialData.messagesFor(widget.thread.id));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(id: 'new', text: text, isMe: true, time: 'Now'));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: WtvaColors.dark300,
              backgroundImage: t.avatarUrl != null ? NetworkImage(t.avatarUrl!) : null,
              child: t.avatarUrl == null
                  ? Icon(t.isVenue ? Icons.storefront : Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  if (t.isVenue)
                    const Text('Business', style: TextStyle(fontSize: 11, color: WtvaColors.lavender300)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showWtvaActionSheet(
              context,
              title: widget.thread.name,
              actions: [
                ('Mute', Icons.notifications_off_outlined, () {
                  showWtvaSnack(context, 'Notifications muted');
                }),
                ('Block', Icons.block, () {
                  showWtvaSnack(context, 'User blocked (demo)');
                }),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                    decoration: BoxDecoration(
                      color: m.isMe ? WtvaColors.accentPurpleDeep : WtvaColors.dark400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.text,
                          style: TextStyle(
                            height: 1.35,
                            color: m.isMe ? WtvaColors.onPrimary : WtvaColors.neutral50,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.time,
                          style: TextStyle(
                            fontSize: 10,
                            color: m.isMe ? WtvaColors.onPrimary.withValues(alpha: 0.55) : WtvaColors.neutral300,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
              color: WtvaColors.dark400,
              border: Border(top: BorderSide(color: WtvaColors.night200)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => showWtvaSnack(context, 'Photo attachment added (demo)'),
                  icon: const Icon(Icons.add_circle_outline, color: WtvaColors.lavender300),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: WtvaColors.neutral50),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send, color: WtvaColors.accentPurple),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
