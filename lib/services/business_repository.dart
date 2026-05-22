import '../data/ranking_rules.dart';
import '../models/business/business_models.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'supabase_bootstrap.dart';
import 'supabase_data.dart';
import 'user_service.dart';

/// Supabase persistence for business portal data.
class BusinessRepository {
  BusinessRepository._();
  static final BusinessRepository instance = BusinessRepository._();

  String? get _ownerId => UserService().currentUser?.id;

  Future<String?> primaryVenueId() async {
    final user = UserService().currentUser;
    final meta = user?.metadata;
    if (meta != null) {
      final v = meta['venueId'] as String?;
      if (v != null && v.isNotEmpty) return v;
      final list = meta['managedVenueIds'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) return list.first as String;
    }
    if (!SupabaseData.syncAuth) return 'post-oak';
    final ownerId = _ownerId;
    if (ownerId == null) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client
          .from('venues')
          .select('id')
          .eq('owner_id', ownerId)
          .limit(1)
          .maybeSingle();
      final id = row?['id'] as String?;
      if (id != null) return id;
      // First-time owners: attach demo venue if none claimed yet
      await client.from('venues').update({'owner_id': ownerId}).eq('id', 'post-oak');
      return 'post-oak';
    } catch (_) {
      return null;
    }
  }

  Future<BusinessVenueProfile?> fetchVenueProfile() async {
    if (!SupabaseData.syncAuth) return null;
    final venueId = await primaryVenueId();
    if (venueId == null) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client.from('venues').select().eq('id', venueId).maybeSingle();
      if (row == null) return null;
      final cats = row['categories'];
      final services = row['services'];
      return BusinessVenueProfile(
        venueName: row['name'] as String? ?? 'Venue',
        address: row['address'] as String? ?? '',
        phone: row['phone'] as String? ?? '',
        description: row['description'] as String? ?? '',
        categories: cats is List ? cats.map((e) => e.toString()).toList() : const [],
        serviceOptions: services is List ? services.map((e) => e.toString()).toList() : const [],
        tier: _tierFromString(row['subscription_tier'] as String?),
        verified: row['verified'] as bool? ?? false,
        verificationDocumentPath: row['verification_document_path'] as String?,
        verificationStatus: row['verification_status'] as String? ?? 'none',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveVenueProfile(BusinessVenueProfile profile, {String? venueId}) async {
    if (!SupabaseData.syncAuth) return;
    final id = venueId ?? await primaryVenueId();
    final ownerId = _ownerId;
    if (id == null || ownerId == null) return;
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
      await client.from('venues').update({
        'name': profile.venueName,
        'address': profile.address,
        'phone': profile.phone,
        'description': profile.description,
        'categories': profile.categories,
        'services': profile.serviceOptions,
        'subscription_tier': profile.tier.name,
        'verified': profile.verified,
        'verification_document_path': profile.verificationDocumentPath,
        'verification_status': profile.verificationStatus,
        'owner_id': ownerId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (_) {}
  }

  Future<String?> createVenueForOwner({
    required BusinessVenueProfile profile,
    required String ownerId,
  }) async {
    if (!SupabaseData.syncAuth) return 'post-oak';
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    final id = 'v-${ownerId.substring(0, 8)}';
    try {
      await client.from('venues').upsert({
        'id': id,
        'name': profile.venueName,
        'venue_type': profile.categories.isNotEmpty ? profile.categories.first : 'Bars',
        'address': profile.address,
        'description': profile.description,
        'phone': profile.phone,
        'categories': profile.categories,
        'services': profile.serviceOptions,
        'subscription_tier': profile.tier.name,
        'verified': false,
        'verification_document_path': profile.verificationDocumentPath,
        'verification_status': profile.verificationStatus,
        'owner_id': ownerId,
        'image_url':
            'https://images.unsplash.com/photo-1571266028245-e68f8574baca?w=800&q=80',
      });
      await AuthService().updateUserProfile(
        userId: ownerId,
        role: UserRole.venueOwner,
        metadata: {'venueId': id, 'managedVenueIds': [id]},
      );
      final user = UserService().currentUser;
      if (user != null && user.id == ownerId) {
        UserService().setUser(
          user.copyWith(
            role: UserRole.venueOwner,
            metadata: {'venueId': id, 'managedVenueIds': [id]},
          ),
        );
      }
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<List<BusinessTalentProfile>> fetchTalentBrowse({
    BusinessBrowseFilters? filters,
  }) async {
    if (!SupabaseData.syncAuth) return [];
    final client = SupabaseBootstrap.client;
    if (client == null) return [];
    try {
      final rows = await client
          .from('users')
          .select('id, name, profile_image_url, metadata, role, user_rankings(total_points)')
          .eq('role', 'customer')
          .limit(40);

      final list = <BusinessTalentProfile>[];
      for (final raw in rows) {
        final row = raw as Map<String, dynamic>;
        final rankings = row['user_rankings'] as Map<String, dynamic>?;
        final points = rankings?['total_points'] as int? ?? 0;
        final tier = RankingRules.tierForPoints(points);
        final meta = row['metadata'] as Map<String, dynamic>? ?? {};
        list.add(
          BusinessTalentProfile(
            id: row['id'] as String,
            name: row['name'] as String? ?? 'User',
            tier: tier.name,
            points: points,
            city: meta['city'] as String? ?? 'Houston',
            avatarUrl: row['profile_image_url'] as String?,
            age: meta['age'] as int? ?? 25,
            gender: meta['gender'] as String? ?? 'Any',
            bio: meta['bio'] as String? ?? 'Nightlife regular · open to paid venue invites.',
          ),
        );
      }

      var result = list;
      final f = filters;
      if (f != null) {
        if (f.location != 'Any') {
          result = result.where((t) => t.city == f.location).toList();
        }
        if (f.sortBy == 'Highest rank') {
          result.sort((a, b) => b.points.compareTo(a.points));
        } else if (f.sortBy == 'Lowest rank') {
          result.sort((a, b) => a.points.compareTo(b.points));
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<List<BusinessBooking>> fetchBookings() async {
    if (!SupabaseData.syncAuth) return [];
    final ownerId = _ownerId;
    if (ownerId == null) return [];
    final client = SupabaseBootstrap.client;
    if (client == null) return [];
    try {
      final rows = await client
          .from('talent_bookings')
          .select('*, users!talent_user_id(name)')
          .eq('owner_id', ownerId)
          .order('event_at', ascending: false);

      return rows.map(_bookingFromRow).toList();
    } catch (_) {
      return [];
    }
  }

  BusinessBooking _bookingFromRow(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    final talent = row['users'] as Map<String, dynamic>? ??
        row['talent'] as Map<String, dynamic>?;
    final talentName = talent?['name'] as String? ?? 'Guest';
    return BusinessBooking(
      id: row['id'] as String,
      talentId: row['talent_user_id'] as String,
      talentName: talentName,
      status: _statusFromString(row['status'] as String?),
      eventAt: DateTime.parse(row['event_at'] as String),
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      note: row['note'] as String? ?? '',
    );
  }

  Future<BusinessBooking?> insertBooking({
    required String venueId,
    required BusinessTalentProfile talent,
    required DateTime eventAt,
    required double amount,
    String note = '',
  }) async {
    if (!SupabaseData.syncAuth) return null;
    final ownerId = _ownerId;
    if (ownerId == null) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client
          .from('talent_bookings')
          .insert({
            'venue_id': venueId,
            'owner_id': ownerId,
            'talent_user_id': talent.id,
            'status': 'pending',
            'event_at': eventAt.toUtc().toIso8601String(),
            'amount': amount,
            'note': note,
          })
          .select()
          .single();
      return _bookingFromRow(row);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateBookingStatus(String id, BusinessBookingStatus status) async {
    if (!SupabaseData.syncAuth) return;
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
      await client.from('talent_bookings').update({
        'status': _statusToString(status),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (_) {}
  }

  Future<List<BusinessPromotion>> fetchPromotions() async {
    if (!SupabaseData.syncAuth) return [];
    final ownerId = _ownerId;
    if (ownerId == null) return [];
    final client = SupabaseBootstrap.client;
    if (client == null) return [];
    try {
      final rows = await client
          .from('venue_promotions')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      return rows.map(_promoFromRow).toList();
    } catch (_) {
      return [];
    }
  }

  Future<BusinessPromotion?> insertPromotion({
    required String venueId,
    required String title,
    required String description,
    required String status,
    required String detail,
  }) async {
    if (!SupabaseData.syncAuth) return null;
    final ownerId = _ownerId;
    if (ownerId == null) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client
          .from('venue_promotions')
          .insert({
            'venue_id': venueId,
            'owner_id': ownerId,
            'title': title,
            'description': description,
            'status': status,
            'detail': detail,
          })
          .select()
          .single();
      return _promoFromRow(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<BusinessCheckInRecord>> fetchVenueCheckIns({int limit = 20}) async {
    if (!SupabaseData.syncAuth) return [];
    final venueId = await primaryVenueId();
    if (venueId == null) return [];
    final client = SupabaseBootstrap.client;
    if (client == null) return [];
    try {
      final rows = await client
          .from('check_ins')
          .select('id, started_at, users(name, profile_image_url)')
          .eq('venue_id', venueId)
          .order('started_at', ascending: false)
          .limit(limit);

      return rows.map((raw) {
        final row = raw as Map<String, dynamic>;
        final user = row['users'] as Map<String, dynamic>?;
        final started = row['started_at'] as String?;
        return BusinessCheckInRecord(
          id: row['id'] as String,
          guestName: user?['name'] as String? ?? 'Guest',
          timeAgo: _timeAgo(started),
          avatarUrl: user?['profile_image_url'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePayoutMethod(String? method) async {
    if (!SupabaseData.syncAuth) return;
    final venueId = await primaryVenueId();
    if (venueId == null) return;
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
      await client.from('venues').update({'payout_method': method}).eq('id', venueId);
    } catch (_) {}
  }

  Future<String?> fetchPayoutMethod() async {
    if (!SupabaseData.syncAuth) return null;
    final venueId = await primaryVenueId();
    if (venueId == null) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client.from('venues').select('payout_method').eq('id', venueId).maybeSingle();
      return row?['payout_method'] as String?;
    } catch (_) {
      return null;
    }
  }

  BusinessPromotion _promoFromRow(dynamic raw) {
    final row = raw as Map<String, dynamic>;
    return BusinessPromotion(
      id: row['id'] as String,
      title: row['title'] as String,
      status: _promoStatusLabel(row['status'] as String?),
      detail: row['detail'] as String? ?? '',
      description: row['description'] as String? ?? '',
    );
  }

  static String _promoStatusLabel(String? s) {
    switch (s) {
      case 'live':
        return 'Live';
      case 'scheduled':
        return 'Scheduled';
      default:
        return s ?? 'Draft';
    }
  }

  static BusinessSubscriptionTier _tierFromString(String? s) {
    switch (s) {
      case 'silver':
        return BusinessSubscriptionTier.silver;
      case 'platinum':
        return BusinessSubscriptionTier.platinum;
      default:
        return BusinessSubscriptionTier.gold;
    }
  }

  static BusinessBookingStatus _statusFromString(String? s) {
    switch (s) {
      case 'confirmed':
        return BusinessBookingStatus.confirmed;
      case 'checkedIn':
        return BusinessBookingStatus.checkedIn;
      case 'completed':
        return BusinessBookingStatus.completed;
      case 'cancelled':
        return BusinessBookingStatus.cancelled;
      default:
        return BusinessBookingStatus.pending;
    }
  }

  static String _statusToString(BusinessBookingStatus s) {
    switch (s) {
      case BusinessBookingStatus.confirmed:
        return 'confirmed';
      case BusinessBookingStatus.checkedIn:
        return 'checkedIn';
      case BusinessBookingStatus.completed:
        return 'completed';
      case BusinessBookingStatus.cancelled:
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  static String _timeAgo(String? iso) {
    if (iso == null) return 'Just now';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso));
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours} hr ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
      return 'Just now';
    } catch (_) {
      return 'Just now';
    }
  }
}
