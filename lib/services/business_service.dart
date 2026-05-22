import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_business_data.dart';
import '../models/business/business_models.dart';
import 'business_repository.dart';
import 'supabase_data.dart';

/// Business portal state — Supabase when authenticated, mock fallback for demo auth.
class BusinessService extends ChangeNotifier {
  BusinessService._();
  static final BusinessService instance = BusinessService._();

  static const _onboardingKey = 'wtva_business_registration_complete';

  final _repo = BusinessRepository.instance;

  BusinessVenueProfile profile = BusinessVenueProfile();
  BusinessBrowseFilters filters = BusinessBrowseFilters();
  List<BusinessBooking> bookings = [];
  List<BusinessPromotion> promotions = [];
  List<BusinessCheckInRecord> venueCheckIns = [];
  bool registrationComplete = false;
  String? payoutMethod;
  String? _venueId;
  bool _loaded = false;

  bool get usesRemoteData => SupabaseData.syncAuth;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    registrationComplete = prefs.getBool(_onboardingKey) ?? false;

    if (SupabaseData.syncAuth) {
      await _loadRemote();
    } else {
      _loadMock();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    _loaded = false;
    await load();
  }

  Future<void> _loadRemote() async {
    _venueId = await _repo.primaryVenueId();
    final remoteProfile = await _repo.fetchVenueProfile();
    if (remoteProfile != null) {
      profile = remoteProfile;
    } else if (_venueId != null) {
      profile = BusinessVenueProfile(venueName: 'My venue');
    }

    payoutMethod = await _repo.fetchPayoutMethod();
    bookings = await _repo.fetchBookings();
    promotions = await _repo.fetchPromotions();
    venueCheckIns = await _repo.fetchVenueCheckIns();

    if (bookings.isEmpty && promotions.isEmpty) {
      _loadMock();
    }
  }

  void _loadMock() {
    profile = BusinessVenueProfile(
      venueName: MockBusinessData.venueName,
      tier: BusinessSubscriptionTier.gold,
      verified: true,
    );
    bookings = MockBusinessData.initialBookings();
    promotions = MockBusinessData.initialPromotions();
    venueCheckIns = MockBusinessData.checkIns;
  }

  Future<void> markRegistrationComplete() async {
    registrationComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<void> updateProfile(BusinessVenueProfile p) async {
    profile = p;
    if (SupabaseData.syncAuth) {
      await _repo.saveVenueProfile(p, venueId: _venueId);
    }
    notifyListeners();
  }

  void updateFilters(BusinessBrowseFilters f) {
    filters = f;
    notifyListeners();
  }

  Future<BusinessBooking> addBooking({
    required BusinessTalentProfile talent,
    required DateTime eventAt,
    required double amount,
    String note = '',
  }) async {
    if (SupabaseData.syncAuth) {
      _venueId ??= await _repo.primaryVenueId();
      final remote = await _repo.insertBooking(
        venueId: _venueId ?? 'post-oak',
        talent: talent,
        eventAt: eventAt,
        amount: amount,
        note: note,
      );
      if (remote != null) {
        bookings = [remote, ...bookings];
        notifyListeners();
        return remote;
      }
    }

    final b = BusinessBooking(
      id: 'bk-${DateTime.now().millisecondsSinceEpoch}',
      talentId: talent.id,
      talentName: talent.name,
      status: BusinessBookingStatus.pending,
      eventAt: eventAt,
      amount: amount,
      note: note,
    );
    bookings = [b, ...bookings];
    notifyListeners();
    return b;
  }

  Future<void> advanceBooking(String id, BusinessBookingStatus status) async {
    if (SupabaseData.syncAuth) {
      await _repo.updateBookingStatus(id, status);
      bookings = await _repo.fetchBookings();
    } else {
      bookings = bookings.map((b) => b.id == id ? b.copyWith(status: status) : b).toList();
    }
    notifyListeners();
  }

  BusinessBooking? bookingById(String id) {
    for (final b in bookings) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<void> addPromotion(BusinessPromotion p) async {
    if (SupabaseData.syncAuth) {
      _venueId ??= await _repo.primaryVenueId();
      final remote = await _repo.insertPromotion(
        venueId: _venueId ?? 'post-oak',
        title: p.title,
        description: p.description,
        status: p.status.toLowerCase() == 'live' ? 'live' : 'scheduled',
        detail: p.detail,
      );
      if (remote != null) {
        promotions = [remote, ...promotions];
        notifyListeners();
        return;
      }
    }
    promotions = [p, ...promotions];
    notifyListeners();
  }

  Future<void> setPayoutMethod(String? method) async {
    payoutMethod = method;
    if (SupabaseData.syncAuth) {
      await _repo.savePayoutMethod(method);
    }
    notifyListeners();
  }

  Future<List<BusinessTalentProfile>> filteredTalent() async {
    if (SupabaseData.syncAuth) {
      final remote = await _repo.fetchTalentBrowse(filters: filters);
      if (remote.isNotEmpty) return remote;
    }
    return _mockFilteredTalent();
  }

  List<BusinessTalentProfile> _mockFilteredTalent() {
    var list = List<BusinessTalentProfile>.from(MockBusinessData.talentProfiles);
    if (filters.location != 'Any') {
      list = list.where((t) => t.city == filters.location).toList();
    }
    if (filters.sortBy == 'Highest rank') {
      list.sort((a, b) => b.points.compareTo(a.points));
    } else if (filters.sortBy == 'Lowest rank') {
      list.sort((a, b) => a.points.compareTo(b.points));
    }
    return list;
  }

  Future<BusinessTalentProfile?> talentById(String id) async {
    final list = await filteredTalent();
    for (final t in list) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Call after login / registration to pull owner data.
  Future<void> onAuthChanged() async {
    _loaded = false;
    await load();
  }
}
