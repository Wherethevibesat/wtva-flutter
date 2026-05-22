import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_check_in_history_data.dart';
import '../data/ranking_rules.dart';
import '../models/leaderboard_entry.dart';
import '../models/points_reason.dart';
import '../models/rank_tier.dart';
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
    var points = prefs.getInt('$_pointsKeyPrefix$userId') ?? _seedPoints(userId);
    if (SupabaseData.syncAuth && userId != 'guest' && !userId.startsWith('demo-')) {
      final remote = await RankingRepository.instance.fetchPoints(userId);
      if (remote != null) points = remote;
    }
    _pointsByUser[userId] = points;

    final historyJson = prefs.getString('$_historyKeyPrefix$userId');
    if (historyJson != null) {
      try {
        final list = jsonDecode(historyJson) as List<dynamic>;
        _history
          ..clear()
          ..addAll(list.map((e) => _historyFromJson(e as Map<String, dynamic>)));
      } catch (_) {
        _seedHistory();
      }
    } else {
      _seedHistory();
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

  int _seedPoints(String userId) {
    if (userId == 'customer-1') return 14972;
    return 0;
  }

  void _seedHistory() {
    if (_history.isNotEmpty) return;
    _history.addAll(MockCheckInHistoryData.entries);
  }

  int get currentPoints {
    if (UserService().isGuest) return 0;
    final id = _userId;
    if (id == null) return 0;
    return _pointsByUser[id] ?? _seedPoints(id);
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
    final total = (_pointsByUser[userId] ?? _seedPoints(userId)) + delta;
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
  Future<List<PointsAward>> beginCheckInSession({
    required String venueId,
    required String venueName,
    required String imageUrl,
    bool includePostBonus = false,
  }) async {
    await load();
    final awards = <PointsAward>[];

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

    if (!session.checkInAwarded) {
      awards.add(await award(PointsReason.checkIn));
      session.checkInAwarded = true;
      await _appendHistory(
        venueId: venueId,
        venueName: venueName,
        imageUrl: imageUrl,
        pointsEarned: RankingRules.checkInPoints,
        hasPost: false,
      );
    }

    if (includePostBonus && !session.postAwarded) {
      awards.add(await award(PointsReason.checkInPost));
      session.postAwarded = true;
      if (_history.isNotEmpty && _history.first.venueId == venueId) {
        final first = _history.first;
        _history[0] = CheckInHistoryEntry(
          id: first.id,
          venueId: first.venueId,
          venueName: first.venueName,
          imageUrl: first.imageUrl,
          dateLabel: first.dateLabel,
          pointsEarned: first.pointsEarned + RankingRules.checkInPostPoints,
          hasPost: true,
        );
        await _persistHistory();
      }
    }

    await _persistSession();
    notifyListeners();
    return awards;
  }

  /// Awards +10 per newly completed full hour while checked in.
  Future<PointsAward?> awardHourlyIfNeeded(Duration elapsed) async {
    await load();
    final session = _activeSession;
    if (session == null) return null;

    final fullHours = elapsed.inHours;
    if (fullHours <= session.hoursAwarded) return null;

    final newHours = fullHours - session.hoursAwarded;
    session.hoursAwarded = fullHours;
    await _persistSession();

    return award(
      PointsReason.hourlyStay,
      amount: newHours * RankingRules.hourlyStayPoints,
    );
  }

  Future<void> endCheckInSession() async {
    _activeSession = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }

  Future<PointsAward> awardBusinessInvite() => award(PointsReason.businessInvite);

  List<LeaderboardEntry> globalLeaderboard() {
    final remote = _remoteGlobalLeaderboard;
    if (remote != null && remote.isNotEmpty) return remote;

    if (UserService().isGuest) {
      const npc = [
        ('nova_vibes', 'Nova Vibes', 48210),
        ('dj_kira', 'DJ Kira', 39120),
        ('miles_out', 'Miles Out', 28450),
        ('lex_night', 'Lex Night', 14200),
        ('sasha_go', 'Sasha Go', 12880),
      ];
      const avatar =
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&q=80';
      return List.generate(npc.length, (i) {
        final e = npc[i];
        return LeaderboardEntry(
          rank: i + 1,
          id: e.$1,
          name: e.$2,
          avatarUrl: avatar,
          points: e.$3,
          tierName: RankingRules.tierForPoints(e.$3).name,
          isCurrentUser: false,
        );
      });
    }

    final user = UserService().currentUser;
    final userName = user?.name ?? 'You';
    final userId = user?.id ?? 'you';
    final userPoints = currentPoints;

    const npc = [
      ('nova_vibes', 'Nova Vibes', 48210),
      ('dj_kira', 'DJ Kira', 39120),
      ('miles_out', 'Miles Out', 28450),
      ('lex_night', 'Lex Night', 14200),
      ('sasha_go', 'Sasha Go', 12880),
      ('rio_pulse', 'Rio Pulse', 11540),
      ('cam_hot', 'Cam Hot', 9820),
      ('tia_live', 'Tia Live', 8640),
      ('ben_spot', 'Ben Spot', 7200),
    ];

    const avatar =
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&q=80';

    final rows = <({String id, String name, int points, bool isYou})>[
      ...npc.map((e) => (id: e.$1, name: e.$2, points: e.$3, isYou: false)),
      (id: userId, name: userName, points: userPoints, isYou: true),
    ]..sort((a, b) => b.points.compareTo(a.points));

    return List.generate(rows.length, (i) {
      final r = rows[i];
      return LeaderboardEntry(
        rank: i + 1,
        id: r.id,
        name: r.isYou ? userName : r.name,
        avatarUrl: avatar,
        points: r.points,
        tierName: RankingRules.tierForPoints(r.points).name,
        isCurrentUser: r.isYou,
      );
    });
  }

  List<LeaderboardEntry> followersLeaderboard() {
    final global = globalLeaderboard();
    const followerIds = {'lex_night', 'sasha_go', 'tia_live', 'ben_spot'};
    const followsYouIds = {'lex_night', 'sasha_go', 'tia_live'};

    final filtered = global
        .where((e) => followerIds.contains(e.id) || e.isCurrentUser)
        .toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    return List.generate(filtered.length, (i) {
      final e = filtered[i];
      return LeaderboardEntry(
        rank: i + 1,
        id: e.id,
        name: e.name,
        avatarUrl: e.avatarUrl,
        points: e.points,
        tierName: e.tierName,
        isCurrentUser: e.isCurrentUser,
        followsYou: followsYouIds.contains(e.id),
      );
    });
  }

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

  Future<void> _persistPoints(String userId) async {
    final total = _pointsByUser[userId] ?? 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_pointsKeyPrefix$userId', total);
    if (SupabaseData.syncAuth && !userId.startsWith('demo-')) {
      await RankingRepository.instance.upsertPoints(userId, total);
    }
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
