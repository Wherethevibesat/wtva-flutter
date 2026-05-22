import 'package:flutter/material.dart';

import '../../services/ranking_service.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';
import '../../widgets/wtva/rank_congrats_dialog.dart';
import '../../widgets/wtva/wtva_leaderboard_panel.dart';
import '../../widgets/wtva/wtva_rank_progress.dart';
import '../../widgets/wtva/wtva_rank_tier_card.dart';
import 'points_info_sheet.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _ranking = RankingService.instance;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowRankUp());
  }

  Future<void> _maybeShowRankUp() async {
    if (!mounted) return;
    final newRank = _ranking.consumePendingRankUp();
    if (newRank != null) {
      await RankCongratsDialog.show(context, newRank: newRank);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = UserService().isGuest;
    final points = _ranking.currentPoints;
    final rank = _ranking.currentRank;
    final milestones = _ranking.progressMilestones;
    final tiers = _ranking.tiers;

    return ListenableBuilder(
      listenable: _ranking,
      builder: (context, _) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(color: WtvaColors.headerBlur),
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rankings',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                    ),
                    if (isGuest) ...[
                      const SizedBox(height: 12),
                      Material(
                        color: WtvaColors.dark400,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => AccountGate.requireSignIn(context),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Sign up to earn points and appear on the leaderboard.',
                              style: TextStyle(fontSize: 13, color: WtvaColors.neutral200, height: 1.35),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: WtvaColors.rankBlueGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.military_tech, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rank,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: WtvaColors.neutral50,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPoints(points),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: WtvaColors.neutral50,
                              ),
                            ),
                            const Text(
                              'POINTS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: WtvaColors.neutral100,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_ranking.pointsToNextTier > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_formatPoints(_ranking.pointsToNextTier)} pts to ${_ranking.nextTier?.name ?? 'next rank'}',
                        style: const TextStyle(fontSize: 13, color: WtvaColors.neutral300),
                      ),
                    ],
                    const SizedBox(height: 24),
                    WtvaRankProgress(currentPoints: points, milestones: milestones),
                    const SizedBox(height: 24),
                    _RankingTabs(
                      selectedIndex: _tabIndex,
                      onSelected: (i) => setState(() => _tabIndex = i),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_tabIndex == 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ranks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: WtvaColors.neutral50,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => PointsInfoSheet.show(context),
                          child: const Text(
                            'How to get points',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: WtvaColors.lavender300,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...tiers.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: WtvaRankTierCard(
                          tier: t,
                          isCurrent: _ranking.isCurrentTier(t),
                        ),
                      ),
                    ),
                  ] else if (_tabIndex == 1)
                    WtvaLeaderboardPanel.global()
                  else
                    WtvaLeaderboardPanel.followers(),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatPoints(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _RankingTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _RankingTabs({required this.selectedIndex, required this.onSelected});

  static const _labels = ['My Rank', 'Global Ranks', 'Followers'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final selected = i == selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(i),
            child: Column(
              children: [
                Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? WtvaColors.neutral50 : WtvaColors.neutral200,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: selected ? WtvaColors.buttonGradient : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
