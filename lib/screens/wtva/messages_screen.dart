import 'package:flutter/material.dart';
import '../../data/mock_messages_data.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';
import 'chat/chat_conversation_screen.dart';
import 'registration/registration_flow.dart';
import 'wtva_login_screen.dart';

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
      return const Scaffold(
        backgroundColor: WtvaColors.dark500,
        body: SafeArea(child: _InboxMembersGate()),
      );
    }

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.w800)),
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
          MockMessagesData.threads.isEmpty
              ? const _EmptyInbox(
                  icon: Icons.chat_bubble_outline,
                  title: 'No messages yet',
                  subtitle: 'When venues or friends message you, they’ll show up here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: MockMessagesData.threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ThreadTile(
                    thread: MockMessagesData.threads[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatConversationScreen(thread: MockMessagesData.threads[i]),
                      ),
                    ),
                  ),
                ),
          const _EmptyInbox(
            icon: Icons.person_add_outlined,
            title: 'No requests',
            subtitle: 'Message requests will appear here when available.',
          ),
        ],
      ),
    );
  }
}

class _InboxMembersGate extends StatelessWidget {
  const _InboxMembersGate();

  Future<void> _openLogin(BuildContext context) async {
    UserService().logout();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WtvaLoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openSignup(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationFlow()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: [
        const Text(
          'Inbox',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: WtvaColors.night200),
            boxShadow: WtvaColors.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: WtvaColors.buttonGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: WtvaColors.buttonShadow,
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: WtvaColors.onPrimary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Messages are for members',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Create a free account to chat with venues, get check-in invites, and keep your nightlife conversations in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: WtvaColors.neutral200,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              const _InboxPerk(
                icon: Icons.storefront_outlined,
                label: 'Message venues directly',
              ),
              const SizedBox(height: 10),
              const _InboxPerk(
                icon: Icons.confirmation_number_outlined,
                label: 'Get check-in invites & updates',
              ),
              const SizedBox(height: 10),
              const _InboxPerk(
                icon: Icons.people_alt_outlined,
                label: 'Chat with friends going out',
              ),
              const SizedBox(height: 28),
              WtvaGradientButton(
                label: 'Log in',
                onPressed: () => _openLogin(context),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _openSignup(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WtvaColors.accentPurple,
                    backgroundColor: WtvaColors.dark400,
                    side: const BorderSide(color: WtvaColors.accentPurple, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Create free account'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InboxPerk extends StatelessWidget {
  const _InboxPerk({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WtvaColors.dark300,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: WtvaColors.accentPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: WtvaColors.neutral50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: WtvaColors.neutral300),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WtvaColors.neutral300, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
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
