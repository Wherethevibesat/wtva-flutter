import 'package:flutter/material.dart';
import '../../data/mock_notifications_data.dart';
import '../../theme/figma_theme.dart';
import '../../services/ranking_service.dart';
import '../../utils/ranking_award_feedback.dart';
import '../../utils/wtva_feedback.dart';
import 'chat/chat_conversation_screen.dart';
import '../../data/mock_messages_data.dart';
import 'ranking_screen.dart';
import 'venue_detail_screen.dart';

class WtvaNotificationsScreen extends StatefulWidget {
  const WtvaNotificationsScreen({super.key});

  @override
  State<WtvaNotificationsScreen> createState() => _WtvaNotificationsScreenState();
}

class _WtvaNotificationsScreenState extends State<WtvaNotificationsScreen> {
  late List<AppNotification> _items;

  @override
  void initState() {
    super.initState();
    _items = List<AppNotification>.from(MockNotificationsData.items);
  }

  void _markAllRead() {
    setState(() {
      _items = _items
          .map((n) => AppNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                timeAgo: n.timeAgo,
                kind: n.kind,
                unread: false,
              ))
          .toList();
    });
    showWtvaSnack(context, 'All notifications marked read', icon: Icons.done_all);
  }

  void _openNotification(AppNotification n) {
    setState(() {
      final i = _items.indexWhere((x) => x.id == n.id);
      if (i >= 0) {
        _items[i] = AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          timeAgo: n.timeAgo,
          kind: n.kind,
          unread: false,
        );
      }
    });

    switch (n.kind) {
      case IconKind.rank:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingScreen()));
        break;
      case IconKind.message:
        if (MockMessagesData.threads.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatConversationScreen(thread: MockMessagesData.threads.first),
            ),
          );
        }
        break;
      case IconKind.invite:
        RankingService.instance.awardBusinessInvite().then((award) {
          if (context.mounted) showPointsAward(context, award);
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VenueDetailScreen(venueId: '2')),
        );
        break;
      case IconKind.checkIn:
      case IconKind.promo:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VenueDetailScreen(venueId: '2')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _NotificationTile(
          n: _items[i],
          onTap: () => _openNotification(_items[i]),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;

  const _NotificationTile({required this.n, required this.onTap});

  IconData get _icon {
    switch (n.kind) {
      case IconKind.invite:
        return Icons.mail_outline;
      case IconKind.rank:
        return Icons.military_tech_outlined;
      case IconKind.checkIn:
        return Icons.location_on_outlined;
      case IconKind.message:
        return Icons.chat_bubble_outline;
      case IconKind.promo:
        return Icons.local_offer_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: n.unread ? WtvaColors.dark300 : WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: n.unread
                ? Border.all(color: WtvaColors.accentPurple.withValues(alpha: 0.35))
                : Border.all(color: WtvaColors.night200.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WtvaColors.night500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: WtvaColors.lavender300, size: 22),
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
                            n.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        Text(
                          n.timeAgo,
                          style: const TextStyle(fontSize: 11, color: WtvaColors.neutral300),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: const TextStyle(fontSize: 13, color: WtvaColors.neutral300, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (n.unread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  decoration: const BoxDecoration(
                    color: WtvaColors.accentPurple,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
