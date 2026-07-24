import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_check_in_history_data.dart'; // CheckInHistoryEntry
import '../data/ranking_rules.dart';
import '../models/leaderboard_entry.dart';
import '../models/points_reason.dart';
import '../models/rank_tier.dart';
import '../services/check_in_repository.dart';
import '../services/location_service.dart';
import '../services/ranking_repository.dart';
import '../services/supabase_data.dart';
import '../services/user_service.dart';

class PointsAward {
  final int amount;
  final int totalAfter;
  final String rankAfter;
  final String? rankUpTo;
  final PointsReason reason;

  const PointsAward({
    required this.amount,
    required this.totalAfter,
    required this.rankAfter,
    this.rankUpTo,
    required this.reason,
  });
}

/// Lifetime points, rank derivation, leaderboards, and check-in accrual.
class RankingService extends ChangeNotifier {
  RankingService._();
  static final RankingService instance = RankingService._();

  static const _pointsKeyPrefix = 'wtva_points_';
  static const _historyKeyPrefix = 'wtva_checkin_history_';
  static const _sessionKey = 'wtva_active_checkin_session';

  final Map<String, int> _pointsByUser = {};
  final List<CheckInHistoryEntry> _history = [];
  bool _loaded = false;
  String? _pendingRankUp;
  _ActiveCheckInSession? _activeSession;
  List<LeaderboardEntry>? _remoteGlobalLeaderboard;

  String? get pendingRankUp => _pendingRankUp;

  String? get _userId => UserService().currentUser?.id;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = _userId ?? 'guest';
    if (UserService().isGuest) {
      _pointsByUser['guest'] = 0;
      _history.clear();
      _loaded = true;
      notifyListeners();
      return;
    }
    var points = prefs.getInt('$_pointsKeyPrefix$userId') ?? 0;
    if (SupabaseData.syncAuth && userId != 'guest' && !userId.startsWith('demo-')) {
      final remote = await RankingRepository.instance.fetchPoints(userId);
      if (remote != null) points = remote;
    }
    _pointsByUser[userId] = points;

    _history.clear();
    if (CheckInRepository.instance.canSync) {
      final remoteHistory = await CheckInRepository.instance.listHistory();
      _history.addAll(remoteHistory);
    } else {
      final historyJson = prefs.getString('$_historyKeyPrefix$userId');
      if (historyJson != null) {
        try {
          final list = jsonDecode(historyJson) as List<dynamic>;
          _history.addAll(
            list.map((e) => _historyFromJson(e as Map<String, dynamic>)),
          );
        } catch (_) {}
      }
    }

    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null) {
      try {
        _activeSession = _ActiveCheckInSession.fromJson(
          jsonDecode(sessionJson) as Map<String, dynamic>,
        );
      } catch (_) {
        _activeSession = null;
      }
    }

    if (SupabaseData.syncAuth) {
      _remoteGlobalLeaderboard = await RankingRepository.instance.fetchGlobalLeaderboard();
    }

    _loaded = true;
    notifyListeners();
  }

  int get currentPoints {
    if (UserService().isGuest) return 0;
    final id = _userId;
    if (id == null) return 0;
    return _pointsByUser[id] ?? 0;
  }

  String get currentRank {
    if (UserService().isGuest) return 'Guest';
    return RankingRules.tierForPoints(currentPoints).name;
  }

  RankTier get currentTier => RankingRules.tierForPoints(currentPoints);

  RankTier? get nextTier => RankingRules.nextTierAfter(currentPoints);

  int get pointsToNextTier => RankingRules.pointsToNextTier(currentPoints);

  List<int> get progressMilestones => RankingRules.progressMilestones(currentPoints);

  List<RankTier> get tiers => RankingRules.tiers;

  bool isCurrentTier(RankTier tier) => tier.name == currentRank;

  List<CheckInHistoryEntry> get checkInHistory => List.unmodifiable(_history);

  /// Clears a pending rank-up notification (e.g. after congrats dialog).
  String? consumePendingRankUp() {
    final r = _pendingRankUp;
    _pendingRankUp = null;
    return r;
  }

  Future<PointsAward> award(PointsReason reason, {int? amount}) async {
    await load();
    final userId = _userId;
    if (userId == null) {
      return PointsAward(
        amount: 0,
        totalAfter: 0,
        rankAfter: RankingRules.tiers.first.name,
        reason: reason,
      );
    }

    final delta = amount ?? RankingRules.pointsFor(reason);
    if (delta <= 0) {
      return PointsAward(
        amount: 0,
        totalAfter: currentPoints,
        rankAfter: currentRank,
        reason: reason,
      );
    }

    final beforeRank = RankingRules.tierForPoints(_pointsByUser[userId] ?? 0).name;
    final total = (_pointsByUser[userId] ?? 0) + delta;
    _pointsByUser[userId] = total;
    final afterRank = RankingRules.tierForPoints(total).name;

    if (_rankIndex(afterRank) > _rankIndex(beforeRank)) {
      _pendingRankUp = afterRank;
    }

    await _persistPoints(userId);
    notifyListeners();

    return PointsAward(
      amount: delta,
      totalAfter: total,
      rankAfter: afterRank,
      rankUpTo: _pendingRankUp,
      reason: reason,
    );
  }

  int _rankIndex(String name) {
    final i = RankingRules.tiers.indexWhere((t) => t.name == name);
    return i < 0 ? 0 : i;
  }

  /// Starts or resumes a check-in session and applies one-time bonuses.
  ///
  /// For real (Supabase-backed) users this calls the `check_in_venue` RPC, which
  /// enforces cooldown/geofence/QR and awards points server-side; it rethrows a
  /// user-facing message when the server rejects the check-in. For demo/guest
  /// sessions it falls back to local, in-memory point accrual.
  Future<List<PointsAward>> beginCheckInSession({
    required String venueId,
    required String venueName,
    required String imageUrl,
    bool includePostBonus = false,
    String? caption,
    String? token,
  }) async {
    await load();

    final sameVenue = _activeSession?.venueId == venueId;
    if (!sameVenue || _activeSession == null) {
      _activeSession = _ActiveCheckInSession(
        venueId: venueId,
        startedAt: DateTime.now(),
        checkInAwarded: false,
        postAwarded: false,
        hoursAwarded: 0,
      );
    }
    final session = _activeSession!;

    if (_serverAuthoritative) {
      final awards = await _serverCheckIn(
        venueId: venueId,
        venueName: venueName,
        imageUrl: imageUrl,
        caption: caption,
        token: token,
      );
      session.checkInAwarded = true;
      await _persistSession();
      notifyListeners();
      return awards;
    }

    // Demo/local check-in: record presence history only (no points economy).
    if (!session.checkInAwarded) {
      session.checkInAwarded = true;
      await _appendHistory(
        venueId: venueId,
        venueName: venueName,
        imageUrl: imageUrl,
        pointsEarned: 0,
        hasPost: false,
      );
    }

    if (includePostBonus && !session.postAwarded) {
      session.postAwarded = true;
      if (_history.isNotEmpty && _history.first.venueId == venueId) {
        final first = _history.first;
        _history[0] = CheckInHistoryEntry(
          id: first.id,
          venueId: first.venueId,
          venueName: first.venueName,
          imageUrl: first.imageUrl,
          dateLabel: first.dateLabel,
          pointsEarned: 0,
          hasPost: true,
        );
        await _persistHistory();
      }
    }

    await _persistSession();
    notifyListeners();
    return const [];
  }

  /// Server-authoritative check-in via the `check_in_venue` RPC. Applies the
  /// server's returned total (never an app-computed absolute) and returns the
  /// awarded breakdown. Rethrows the RPC's user-facing message on rejection.
  Future<List<PointsAward>> _serverCheckIn({
    required String venueId,
    required String venueName,
    required String imageUrl,
    String? caption,
    String? token,
  }) async {
    final location = await LocationService.current();
    final result = await CheckInRepository.instance.checkInViaRpc(
      venueId: venueId,
      caption: caption,
      token: token,
      location: location,
    );
    if (result == null) return [];

    _pendingRankUp = null;

    await _appendHistory(
      venueId: venueId,
      venueName: venueName,
      imageUrl: imageUrl,
      pointsEarned: 0,
      hasPost: caption != null && caption.isNotEmpty,
    );

    return const [];
  }

  /// Weekly leaderboard from the server points ledger (empty for demo sessions).
  Future<List<LeaderboardEntry>> weeklyLeaderboard({int days = 7}) {
    if (!SupabaseData.syncAuth) return Future.value(const []);
    return RankingRepository.instance.fetchLeaderboardWindow(days: days);
  }

  /// Points economy removed — hourly awards are disabled.
  Future<PointsAward?> awardHourlyIfNeeded(Duration elapsed) async => null;

  Future<void> endCheckInSession() async {
    _activeSession = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }

  /// Applies a server-returned absolute total (e.g. after redeeming a reward).
  Future<void> applyServerTotal(int total) async {
    await load();
    final userId = _userId;
    if (userId == null) return;
    _pointsByUser[userId] = total;
    await _persistPoints(userId);
    notifyListeners();
  }

  Future<PointsAward> awardBusinessInvite() async {
    await load();
    // Demo-only local grant; real users' points come from the server ledger.
    if (_serverAuthoritative) {
      return PointsAward(
        amount: 0,
        totalAfter: currentPoints,
        rankAfter: currentRank,
        reason: PointsReason.businessInvite,
      );
    }
    return award(PointsReason.businessInvite);
  }

  List<LeaderboardEntry> globalLeaderboard() {
    final remote = _remoteGlobalLeaderboard;
    if (remote != null && remote.isNotEmpty) return remote;

    // No NPC filler — show only the signed-in user when the remote board is empty.
    if (UserService().isGuest) return const [];

    final user = UserService().currentUser;
    if (user == null) return const [];
    final points = currentPoints;
    return [
      LeaderboardEntry(
        rank: 1,
        id: user.id,
        name: user.name,
        avatarUrl: user.profileImageUrl,
        points: points,
        tierName: RankingRules.tierForPoints(points).name,
        isCurrentUser: true,
      ),
    ];
  }

  /// Followers leaderboard is not wired yet — keep empty until social graph exists.
  List<LeaderboardEntry> followersLeaderboard() => const [];

  Future<void> _appendHistory({
    required String venueId,
    required String venueName,
    required String imageUrl,
    required int pointsEarned,
    required bool hasPost,
  }) async {
    _history.insert(
      0,
      CheckInHistoryEntry(
        id: 'h-${DateTime.now().millisecondsSinceEpoch}',
        venueId: venueId,
        venueName: venueName,
        imageUrl: imageUrl,
        dateLabel: 'Just now',
        pointsEarned: pointsEarned,
        hasPost: hasPost,
      ),
    );
    if (_history.length > 30) {
      _history.removeRange(30, _history.length);
    }
    await _persistHistory();
  }

  /// True when a real Supabase session backs this user — the server ledger is
  /// then the source of truth and the app must not write absolute totals.
  bool get _serverAuthoritative => CheckInRepository.instance.canSync;

  Future<void> _persistPoints(String userId) async {
    final total = _pointsByUser[userId] ?? 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_pointsKeyPrefix$userId', total);
    // NOTE: We intentionally do NOT upsert an absolute total to Supabase here.
    // The server points ledger (check_in_venue / redeem_reward RPCs) is the
    // source of truth; overwriting total_points from the client corrupts it.
  }

  Future<void> _persistHistory() async {
    final userId = _userId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_history.map(_historyToJson).toList());
    await prefs.setString('$_historyKeyPrefix$userId', json);
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeSession == null) {
      await prefs.remove(_sessionKey);
      return;
    }
    await prefs.setString(_sessionKey, jsonEncode(_activeSession!.toJson()));
  }

  Map<String, dynamic> _historyToJson(CheckInHistoryEntry e) => {
        'id': e.id,
        'venueId': e.venueId,
        'venueName': e.venueName,
        'imageUrl': e.imageUrl,
        'dateLabel': e.dateLabel,
        'pointsEarned': e.pointsEarned,
        'hasPost': e.hasPost,
      };

  CheckInHistoryEntry _historyFromJson(Map<String, dynamic> j) => CheckInHistoryEntry(
        id: j['id'] as String,
        venueId: j['venueId'] as String,
        venueName: j['venueName'] as String,
        imageUrl: j['imageUrl'] as String,
        dateLabel: j['dateLabel'] as String,
        pointsEarned: j['pointsEarned'] as int,
        hasPost: j['hasPost'] as bool? ?? false,
      );

  /// Rebind storage when user changes (login / guest).
  Future<void> onUserChanged() async {
    _loaded = false;
    _history.clear();
    _activeSession = null;
    _remoteGlobalLeaderboard = null;
    await load();
  }
}

class _ActiveCheckInSession {
  final String venueId;
  final DateTime startedAt;
  bool checkInAwarded;
  bool postAwarded;
  int hoursAwarded;

  _ActiveCheckInSession({
    required this.venueId,
    required this.startedAt,
    required this.checkInAwarded,
    required this.postAwarded,
    required this.hoursAwarded,
  });

  Map<String, dynamic> toJson() => {
        'venueId': venueId,
        'startedAt': startedAt.toIso8601String(),
        'checkInAwarded': checkInAwarded,
        'postAwarded': postAwarded,
        'hoursAwarded': hoursAwarded,
      };

  factory _ActiveCheckInSession.fromJson(Map<String, dynamic> j) => _ActiveCheckInSession(
        venueId: j['venueId'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        checkInAwarded: j['checkInAwarded'] as bool? ?? false,
        postAwarded: j['postAwarded'] as bool? ?? false,
        hoursAwarded: j['hoursAwarded'] as int? ?? 0,
      );
}
