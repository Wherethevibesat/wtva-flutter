import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/customer_portal_api.dart';
import '../../services/night_package_checkout_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';
import '../../utils/wtva_feedback.dart';
import 'night_package_orders_screen.dart';

/// Waiting room after host (or guest) pays a vibe split share.
class VibeSplitWaitingScreen extends StatefulWidget {
  const VibeSplitWaitingScreen({
    super.key,
    required this.inviteToken,
    this.inviteUrl,
    this.packageTitle,
  });

  final String inviteToken;
  final String? inviteUrl;
  final String? packageTitle;

  @override
  State<VibeSplitWaitingScreen> createState() => _VibeSplitWaitingScreenState();
}

class _VibeSplitWaitingScreenState extends State<VibeSplitWaitingScreen> {
  VibeSplitGroupStatus? _group;
  String? _error;
  bool _loading = true;
  bool _paying = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final group =
          await CustomerPortalApi.instance.fetchVibeSplitGroup(widget.inviteToken);
      if (!mounted) return;
      setState(() {
        _group = group;
        _error = null;
        _loading = false;
      });
      if (group.status == 'paid') {
        _poll?.cancel();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is StateError ? e.message : 'Could not load split';
        _loading = false;
      });
    }
  }

  String _money(double dollars) {
    final whole = dollars == dollars.roundToDouble();
    return '\$${dollars.toStringAsFixed(whole ? 0 : 2)}';
  }

  Future<void> _payGuestShare() async {
    final group = _group;
    final shareId = group?.openGuestShareId;
    if (group == null || shareId == null || _paying) return;

    final ok = await AccountGate.requireSignIn(
      context,
      requireSupabaseSession: true,
      message: 'Sign in to pay your share of this vibe.',
    );
    if (!ok || !mounted) return;

    setState(() => _paying = true);
    try {
      final status = await NightPackageCheckoutService.instance.payShare(
        groupId: group.id,
        shareId: shareId,
      );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      if (status == 'group_paid' || _group?.status == 'paid') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Everyone paid — your vibe is booked.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError ? e.message : 'Payment failed';
      if (msg == 'Payment cancelled') return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    final title = widget.packageTitle ?? group?.packageTitle ?? 'Split vibe';

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        title: const Text('Split pay'),
      ),
      body: _loading && group == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: WtvaColors.neutral50,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  group == null
                      ? (_error ?? 'Loading…')
                      : group.status == 'paid'
                          ? 'Everyone paid — you’re booked.'
                          : group.status == 'expired'
                              ? 'This split expired.'
                              : 'Waiting for friends (${group.paidCount}/${group.shares.length} paid)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: WtvaColors.neutral300,
                  ),
                ),
                if (_error != null && group != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFF87171), fontSize: 13),
                  ),
                ],
                if (group != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: WtvaColors.dark400,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: WtvaColors.night200.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (final share in group.shares) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  share.role == 'host'
                                      ? 'Host'
                                      : (share.label?.trim().isNotEmpty == true
                                          ? share.label!
                                          : 'Friend'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: WtvaColors.neutral50,
                                  ),
                                ),
                              ),
                              Text(
                                _money(share.amount),
                                style: const TextStyle(
                                  color: WtvaColors.neutral100,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                share.status == 'paid' ? 'Paid' : 'Waiting',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: share.status == 'paid'
                                      ? const Color(0xFF4ADE80)
                                      : WtvaColors.neutral300,
                                ),
                              ),
                            ],
                          ),
                          if (share != group.shares.last)
                            const Divider(height: 16, color: WtvaColors.night200),
                        ],
                        const Divider(height: 18, color: WtvaColors.night200),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: WtvaColors.neutral50,
                                ),
                              ),
                            ),
                            Text(
                              _money(group.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: WtvaColors.neutral50,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if ((widget.inviteUrl ?? '').isNotEmpty &&
                      group.status == 'collecting') ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => copyToClipboard(
                        context,
                        widget.inviteUrl!,
                        message: 'Invite link copied',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WtvaColors.neutral100,
                        side: BorderSide(
                          color: WtvaColors.night200.withValues(alpha: 0.9),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Copy invite link',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  if (group.status == 'collecting' &&
                      group.openGuestShareId != null) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _paying ? null : _payGuestShare,
                      style: FilledButton.styleFrom(
                        backgroundColor: WtvaColors.accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        _paying ? 'Processing…' : 'Pay my share',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  if (group.status == 'paid') ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const NightPackageOrdersScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: WtvaColors.accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Open My Plans',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}
