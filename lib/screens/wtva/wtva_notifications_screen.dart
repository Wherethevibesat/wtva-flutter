import 'package:flutter/material.dart';
import '../../data/mock_notifications_data.dart';
import '../../services/notifications_repository.dart';
import '../../theme/figma_theme.dart';
import '../../utils/wtva_feedback.dart';

class WtvaNotificationsScreen extends StatefulWidget {
  const WtvaNotificationsScreen({super.key});

  @override
  State<WtvaNotificationsScreen> createState() => _WtvaNotificationsScreenState();
}

class _WtvaNotificationsScreenState extends State<WtvaNotificationsScreen> {
  List<AppNotification> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await NotificationsRepository.instance.listMine();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await NotificationsRepository.instance.markAllRead();
    if (!mounted) return;
    setState(() {
      _items = _items
          .map(
            (n) => AppNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              timeAgo: n.timeAgo,
              kind: n.kind,
              unread: false,
            ),
          )
          .toList();
    });
    showWtvaSnack(context, 'All notifications marked read', icon: Icons.done_all);
  }

  Future<void> _openNotification(AppNotification n) async {
    if (n.unread) {
      await NotificationsRepository.instance.markRead(n.id);
    }
    if (!mounted) return;
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

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_items.isNotEmpty)
            TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: WtvaColors.accentPurple))
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 40, color: WtvaColors.neutral300),
                        SizedBox(height: 12),
                        Text(
                          'No notifications',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Push and in-app announcements from WTVA will show up here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: WtvaColors.neutral300, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: WtvaColors.accentPurple,
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _NotificationTile(
                      n: _items[i],
                      onTap: () => _openNotification(_items[i]),
                    ),
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
        return Icons.campaign_outlined;
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
                  color: WtvaColors.accentPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: WtvaColors.accentPurple, size: 22),
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
