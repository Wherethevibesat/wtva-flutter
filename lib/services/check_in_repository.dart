import '../config/app_config.dart';
import '../config/dev_auth_config.dart';
import '../services/supabase_bootstrap.dart';
import '../services/user_service.dart';

/// Persists check-ins to Supabase when authenticated with a real session.
class CheckInRepository {
  CheckInRepository._();
  static final CheckInRepository instance = CheckInRepository._();

  String? _activeCheckInId;

  String? get activeCheckInId => _activeCheckInId;

  bool get canSync =>
      AppConfig.useSupabaseData &&
      SupabaseBootstrap.initialized &&
      !DevAuthConfig.useDummyAuth &&
      UserService().currentUser != null;

  Future<String?> startCheckIn({
    required String venueId,
    String? caption,
    String? imageUrl,
  }) async {
    if (!canSync) return null;
    final client = SupabaseBootstrap.client;
    final userId = UserService().currentUser?.id;
    if (client == null || userId == null) return null;

    try {
      final row = await client
          .from('check_ins')
          .insert({
            'user_id': userId,
            'venue_id': venueId,
            if (caption != null) 'caption': caption,
            if (imageUrl != null) 'image_url': imageUrl,
          })
          .select('id')
          .single();
      _activeCheckInId = row['id'] as String?;
      return _activeCheckInId;
    } catch (_) {
      return null;
    }
  }

  Future<void> endCheckIn() async {
    final id = _activeCheckInId;
    if (!canSync || id == null) {
      _activeCheckInId = null;
      return;
    }
    final client = SupabaseBootstrap.client;
    if (client == null) return;

    try {
      await client.from('check_ins').update({
        'ended_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (_) {
      // ignore — local session still ends
    }
    _activeCheckInId = null;
  }

  void clearLocal() => _activeCheckInId = null;
}
