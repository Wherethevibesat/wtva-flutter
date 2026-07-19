import 'package:flutter/material.dart';

import '../../models/reward.dart';
import '../../services/ranking_service.dart';
import '../../services/rewards_repository.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';
import '../../utils/wtva_feedback.dart';

/// Rewards catalog: spend points on perks and view redemption codes.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _repo = RewardsRepository.instance;
  final _ranking = RankingService.instance;

  bool _loading = true;
  List<Reward> _rewards = const [];
  List<Redemption> _redemptions = const [];
  String? _redeemingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rewards = await _repo.listRewards();
    final redemptions = await _repo.listMyRedemptions();
    if (!mounted) return;
    setState(() {
      _rewards = rewards;
      _redemptions = redemptions;
      _loading = false;
    });
  }

  Future<void> _redeem(Reward reward) async {
    if (UserService().isGuest) {
      await AccountGate.requireSignIn(context);
      return;
    }
    setState(() => _redeemingId = reward.id);
    try {
      final result = await _repo.redeem(reward.id);
      await _ranking.applyServerTotal(result.totalPoints);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: WtvaColors.dark400,
          title: const Text('Reward unlocked'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.rewardTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text('Show this code to venue staff:',
                  style: TextStyle(fontSize: 13, color: WtvaColors.neutral300)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: WtvaColors.buttonGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  result.code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: WtvaColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
          ],
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      showWtvaSnack(context, _errorMessage(e), icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _redeemingId = null);
    }
  }

  String _errorMessage(Object error) {
    final raw = error.toString().replaceAll('Exception: ', '');
    final cut = raw.indexOf(', code:');
    final msg = cut > 0 ? raw.substring(0, cut) : raw;
    return msg.replaceAll('PostgrestException(message: ', '').replaceAll(RegExp(r'[)]+$'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Rewards', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListenableBuilder(
          listenable: _ranking,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              _BalanceCard(points: _ranking.currentPoints),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                const _SectionTitle('Available rewards'),
                const SizedBox(height: 12),
                if (_rewards.isEmpty)
                  const _EmptyNote('No rewards available right now. Check back soon.')
                else
                  ..._rewards.map(
                    (r) => _RewardCard(
                      reward: r,
                      balance: _ranking.currentPoints,
                      busy: _redeemingId == r.id,
                      onRedeem: () => _redeem(r),
                    ),
                  ),
                if (_redemptions.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const _SectionTitle('Your codes'),
                  const SizedBox(height: 12),
                  ..._redemptions.map((r) => _RedemptionCard(redemption: r)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int points;
  const _BalanceCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: WtvaColors.buttonGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your points',
            style: TextStyle(fontSize: 13, color: WtvaColors.onPrimary.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 6),
          Text(
            '$points',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: WtvaColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Reward reward;
  final int balance;
  final bool busy;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.reward,
    required this.balance,
    required this.busy,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final affordable = balance >= reward.costPoints;
    final canRedeem = affordable && !reward.soldOut && !busy;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WtvaColors.night200.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reward.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: WtvaColors.dark300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${reward.costPoints} pts',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: WtvaColors.lavender300),
                ),
              ),
            ],
          ),
          if (reward.venueName != null) ...[
            const SizedBox(height: 4),
            Text(reward.venueName!, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
          ],
          if (reward.description != null) ...[
            const SizedBox(height: 8),
            Text(reward.description!, style: const TextStyle(fontSize: 13, color: WtvaColors.neutral200)),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canRedeem ? onRedeem : null,
              style: FilledButton.styleFrom(
                backgroundColor: WtvaColors.accentPurple,
                disabledBackgroundColor: WtvaColors.dark300,
              ),
              child: busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      reward.soldOut
                          ? 'Out of stock'
                          : affordable
                              ? 'Redeem'
                              : 'Need ${reward.costPoints - balance} more pts',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  final Redemption redemption;
  const _RedemptionCard({required this.redemption});

  @override
  Widget build(BuildContext context) {
    final active = redemption.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WtvaColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  redemption.rewardTitle ?? 'Reward',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  redemption.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? WtvaColors.accentGreen : WtvaColors.neutral300,
                  ),
                ),
              ],
            ),
          ),
          Text(
            redemption.code,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: active ? WtvaColors.lavender300 : WtvaColors.neutral300,
              decoration: active ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: WtvaColors.neutral50),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;
  const _EmptyNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, color: WtvaColors.neutral300)),
    );
  }
}
