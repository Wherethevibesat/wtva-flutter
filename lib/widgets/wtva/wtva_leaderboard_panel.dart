import 'package:flutter/material.dart';
import '../../data/mock_leaderboard_data.dart';
import '../../models/leaderboard_entry.dart';
import '../../screens/wtva/profile/user_profile_screen.dart';
import '../../theme/figma_theme.dart';
import '../../services/user_service.dart';
import '../../utils/account_gate.dart';
import '../../utils/wtva_user_helpers.dart';

class WtvaLeaderboardPanel extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String subtitle;
  final bool showFollowsYou;

  const WtvaLeaderboardPanel({
    super.key,
    required this.entries,
    required this.subtitle,
    this.showFollowsYou = false,
  });

  factory WtvaLeaderboardPanel.global() {
    return WtvaLeaderboardPanel(
      entries: MockLeaderboardData.global,
      subtitle: 'Top users nationwide by points',
    );
  }

  factory WtvaLeaderboardPanel.followers() {
    return WtvaLeaderboardPanel(
      entries: MockLeaderboardData.followers,
      subtitle: 'People you follow ranked by points',
      showFollowsYou: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top3 = entries.where((e) => e.rank <= 3).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final rest = entries.where((e) => e.rank > 3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: WtvaColors.neutral300),
        ),
        const SizedBox(height: 20),
        if (top3.length >= 3)
          _Podium(top3: top3, onEntryTap: (e) => _openProfile(context, e)),
        const SizedBox(height: 24),
        ...rest.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LeaderboardRow(
              entry: e,
              showFollowsYou: showFollowsYou,
              onTap: () => _openProfile(context, e),
            ),
          ),
        ),
      ],
    );
  }

  void _openProfile(BuildContext context, LeaderboardEntry entry) {
    if (entry.isCurrentUser) {
      if (UserService().isGuest) {
        AccountGate.requireSignIn(context);
      }
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(user: socialUserFromLeaderboard(entry)),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final void Function(LeaderboardEntry) onEntryTap;

  const _Podium({required this.top3, required this.onEntryTap});

  LeaderboardEntry _at(int rank) => top3.firstWhere((e) => e.rank == rank);

  @override
  Widget build(BuildContext context) {
    final first = _at(1);
    final second = _at(2);
    final third = _at(3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumSlot(entry: second, height: 88, medal: 2, onTap: () => onEntryTap(second))),
        const SizedBox(width: 8),
        Expanded(child: _PodiumSlot(entry: first, height: 108, medal: 1, onTap: () => onEntryTap(first))),
        const SizedBox(width: 8),
        Expanded(child: _PodiumSlot(entry: third, height: 72, medal: 3, onTap: () => onEntryTap(third))),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final int medal;
  final VoidCallback onTap;

  const _PodiumSlot({
    required this.entry,
    required this.height,
    required this.medal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: entry.isCurrentUser ? null : onTap,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final gradients = [
      WtvaColors.rankOrangeGradient,
      WtvaColors.rankBlueGradient,
      WtvaColors.rankPinkGradient,
    ];

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: entry.avatarUrl != null
                  ? NetworkImage(entry.avatarUrl!)
                  : null,
              child: entry.avatarUrl == null
                  ? Text(entry.name[0], style: const TextStyle(fontWeight: FontWeight.w700))
                  : null,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: gradients[medal - 1],
                  shape: BoxShape.circle,
                  border: Border.all(color: WtvaColors.dark500, width: 2),
                ),
                child: Text(
                  '$medal',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          entry.name.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          _formatPoints(entry.points),
          style: const TextStyle(fontSize: 11, color: WtvaColors.neutral300),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: gradients[medal - 1],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.center,
          child: Text(
            entry.tierName.split(' ').first,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  String _formatPoints(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool showFollowsYou;
  final VoidCallback? onTap;

  const _LeaderboardRow({
    required this.entry,
    required this.showFollowsYou,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isCurrentUser;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.isCurrentUser ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? WtvaColors.dark300 : WtvaColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: WtvaColors.accentPurple.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: highlight ? WtvaColors.lavender300 : WtvaColors.neutral300,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundImage:
                entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(entry.name[0], style: const TextStyle(fontSize: 12))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.isCurrentUser ? 'You' : entry.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showFollowsYou && entry.followsYou) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: WtvaColors.night200),
                        ),
                        child: const Text(
                          'Follows you',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: WtvaColors.neutral200,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  entry.tierName,
                  style: const TextStyle(fontSize: 11, color: WtvaColors.neutral300),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPoints(entry.points),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Text(
                'PTS',
                style: TextStyle(fontSize: 10, color: WtvaColors.neutral300),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  String _formatPoints(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
