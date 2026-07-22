import 'package:intl/intl.dart';

import '../data/mock_notifications_data.dart';
import 'supabase_bootstrap.dart';
import 'supabase_data.dart';
import 'user_service.dart';

class NotificationsRepository {
  NotificationsRepository._();
  static final NotificationsRepository instance = NotificationsRepository._();

  Future<List<AppNotification>> listMine({int limit = 50}) async {
    final user = UserService().currentUser;
    if (user == null || UserService().isGuest || !SupabaseData.enabled) {
      return const [];
    }
    final client = SupabaseBootstrap.client;
    if (client == null) return const [];

    try {
      final rows = await client
          .from('user_notifications')
          .select('id, title, body, link, read_at, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return rows.map<AppNotification>((row) {
        final created = DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal();
        return AppNotification(
          id: row['id'] as String,
          title: (row['title'] as String?)?.trim().isNotEmpty == true
              ? row['title'] as String
              : 'Notification',
          body: (row['body'] as String?) ?? '',
          timeAgo: _timeAgo(created),
          kind: IconKind.promo,
          unread: row['read_at'] == null,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> markRead(String id) async {
    final client = SupabaseBootstrap.client;
    final user = UserService().currentUser;
    if (client == null || user == null) return;
    try {
      await client
          .from('user_notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final client = SupabaseBootstrap.client;
    final user = UserService().currentUser;
    if (client == null || user == null) return;
    try {
      await client
          .from('user_notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', user.id)
          .isFilter('read_at', null);
    } catch (_) {}
  }

  String _timeAgo(DateTime? when) {
    if (when == null) return '';
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat.MMMd().format(when);
  }
}
