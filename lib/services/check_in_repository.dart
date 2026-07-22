import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../config/dev_auth_config.dart';
import '../data/mock_check_in_history_data.dart';
import '../models/check_in_result.dart';
import '../services/location_service.dart';
import '../services/supabase_bootstrap.dart';
import '../services/user_service.dart';

/// Persists check-ins to Supabase when authenticated with a real session.
class CheckInRepository {
  CheckInRepository._();
  static final CheckInRepository instance = CheckInRepository._();

  String? _activeCheckInId;

  String? get activeCheckInId => _activeCheckInId;

  void setActiveCheckInId(String? id) => _activeCheckInId = id;

  bool get canSync =>
      AppConfig.useSupabaseData &&
      SupabaseBootstrap.initialized &&
      !DevAuthConfig.useDummyAuth &&
      UserService().currentUser != null;

  /// Check in via the server RPC, which enforces cooldown/geofence/QR and awards
  /// points atomically. Throws with a user-facing message on rejection.
  Future<CheckInResult?> checkInViaRpc({
    required String venueId,
    String? caption,
    String? token,
    DeviceLocation? location,
  }) async {
    if (!canSync) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;

    final data = await client.rpc('check_in_venue', params: {
      'p_venue_id': venueId,
      'p_caption': caption,
      'p_lat': location?.lat,
      'p_lng': location?.lng,
      'p_accuracy': location?.accuracy,
      'p_token': token,
    });

    final map = (data as Map).cast<String, dynamic>();
    final result = CheckInResult.fromMap(map);
    if (result.checkInId.isNotEmpty) _activeCheckInId = result.checkInId;
    return result;
  }

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

  /// Real check-in history for the signed-in user (empty when offline/demo).
  Future<List<CheckInHistoryEntry>> listHistory({int limit = 50}) async {
    if (!canSync) return const [];
    final client = SupabaseBootstrap.client;
    final userId = UserService().currentUser?.id;
    if (client == null || userId == null) return const [];

    try {
      final rows = await client
          .from('check_ins')
          .select(
            'id, venue_id, caption, image_url, started_at, created_at, points_awarded, venues(name, image_url)',
          )
          .eq('user_id', userId)
          .order('started_at', ascending: false)
          .limit(limit);

      return rows.map<CheckInHistoryEntry>((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final venue = row['venues'] as Map<String, dynamic>?;
        final startedRaw = row['started_at'] as String? ?? row['created_at'] as String?;
        final started = startedRaw != null ? DateTime.tryParse(startedRaw)?.toLocal() : null;
        final caption = (row['caption'] as String?)?.trim();
        return CheckInHistoryEntry(
          id: row['id'] as String? ?? '',
          venueId: row['venue_id'] as String? ?? '',
          venueName: venue?['name'] as String? ?? 'Venue',
          imageUrl: (row['image_url'] as String?)?.isNotEmpty == true
              ? row['image_url'] as String
              : (venue?['image_url'] as String? ?? ''),
          dateLabel: started == null
              ? 'Recently'
              : DateFormat('EEE, MMM d · h:mm a').format(started),
          pointsEarned: (row['points_awarded'] as num?)?.toInt() ?? 0,
          hasPost: caption != null && caption.isNotEmpty,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }
}
