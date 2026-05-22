import 'package:flutter/material.dart';
import '../../data/mock_messages_data.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/guest_locked_view.dart';
import 'chat/chat_conversation_screen.dart';
import '../../utils/wtva_feedback.dart';
import 'chat/chat_requests_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (UserService().isGuest) {
      return Scaffold(
        backgroundColor: WtvaColors.dark500,
        appBar: AppBar(
          backgroundColor: WtvaColors.dark500,
          title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: const GuestLockedView(
          title: 'Messages are for members',
          message:
              'Log in or sign up to chat with venues and friends, and receive check-in invites.',
          icon: Icons.chat_bubble_outline,
        ),
      );
    }

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: WtvaColors.accentPurple,
          labelColor: WtvaColors.neutral50,
          unselectedLabelColor: WtvaColors.neutral300,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: MockMessagesData.threads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ThreadTile(
              thread: MockMessagesData.threads[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatConversationScreen(thread: MockMessagesData.threads[i]),
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.person_add_outlined, color: WtvaColors.lavender300),
                title: const Text('View all requests'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatRequestsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: WtvaColors.accentPurpleDeep,
        onPressed: () => _showNewMessageSheet(context),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

void _showFilterSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: WtvaColors.dark400,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Filter messages', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          for (final label in ['All', 'Unread', 'Venues', 'Friends'])
            ListTile(
              title: Text(label),
              trailing: label == 'All' ? const Icon(Icons.check, color: WtvaColors.accentGreen) : null,
              onTap: () {
                Navigator.pop(ctx);
                showWtvaSnack(context, 'Filter: $label');
              },
            ),
        ],
      ),
    ),
  );
}

void _showNewMessageSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: WtvaColors.dark400,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('New message', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          ...MockMessagesData.threads.map(
            (t) => ListTile(
              leading: CircleAvatar(
                backgroundImage: t.avatarUrl != null ? NetworkImage(t.avatarUrl!) : null,
                child: t.avatarUrl == null ? const Icon(Icons.person) : null,
              ),
              title: Text(t.name),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatConversationScreen(thread: t)),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: WtvaColors.dark300,
                backgroundImage:
                    thread.avatarUrl != null ? NetworkImage(thread.avatarUrl!) : null,
                child: thread.avatarUrl == null
                    ? Icon(
                        thread.isVenue ? Icons.storefront : Icons.person,
                        color: WtvaColors.lavender300,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          thread.timeAgo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: WtvaColors.neutral300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thread.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: thread.unread > 0
                            ? WtvaColors.neutral100
                            : WtvaColors.neutral300,
                        fontWeight:
                            thread.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (thread.unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: WtvaColors.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${thread.unread}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: WtvaColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
