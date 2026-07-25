import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/customer_portal_api.dart';
import '../../services/night_package_checkout_service.dart';
import '../../services/supabase_bootstrap.dart';
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
    this.preferredShareId,
  });

  final String inviteToken;
  final String? inviteUrl;
  final String? packageTitle;
  final String? preferredShareId;

  @override
  State<VibeSplitWaitingScreen> createState() => _VibeSplitWaitingScreenState();
}

class _VibeSplitWaitingScreenState extends State<VibeSplitWaitingScreen> {
  VibeSplitGroupStatus? _group;
  String? _error;
  bool _loading = true;
  bool _paying = false;
  String _payStage = 'Processing…';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Never refresh while PaymentSheet is presenting — iOS can hang/hide the sheet.
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_paying) return;
      _refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_paying) return;
    try {
      final group =
          await CustomerPortalApi.instance.fetchVibeSplitGroup(widget.inviteToken);
      if (!mounted || _paying) return;
      setState(() {
        _group = group;
        _error = null;
        _loading = false;
      });
      if (group.status == 'paid') {
        _poll?.cancel();
      }
    } catch (e) {
      if (!mounted || _paying) return;
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

  VibeSplitShare? get _myShare {
    final group = _group;
    if (group == null) return null;
    final user = SupabaseBootstrap.client?.auth.currentUser;
    return group.payableShareFor(
      userId: user?.id,
      userEmail: user?.email,
      preferredShareId: widget.preferredShareId,
    );
  }

  Future<void> _payMyShare() async {
    final group = _group;
    final share = _myShare;
    if (group == null || share == null || _paying) return;

    final ok = await AccountGate.requireSignIn(
      context,
      requireSupabaseSession: true,
      message: 'Sign in to pay your share of this vibe.',
    );
    if (!ok || !mounted) return;

    // Re-resolve after login (host share vs guest).
    final payable = _group?.payableShareFor(
      userId: SupabaseBootstrap.client?.auth.currentUser?.id,
      userEmail: SupabaseBootstrap.client?.auth.currentUser?.email,
      preferredShareId: widget.preferredShareId,
    );
    if (payable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unpaid share found for your account.')),
      );
      return;
    }

    setState(() {
      _paying = true;
      _payStage = 'Loading Stripe…';
    });
    try {
      final status = await NightPackageCheckoutService.instance.payShare(
        context: context,
        groupId: group.id,
        shareId: payable.id,
        amount: payable.amount,
        onStage: (stage) {
          if (!mounted) return;
          setState(() => _payStage = stage);
        },
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
      final msg = e is StateError ? e.message : e.toString();
      if (msg == 'Payment cancelled' || msg.contains('Payment cancelled')) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
      );
    } finally {
      _paying = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    final title = widget.packageTitle ?? group?.packageTitle ?? 'Split vibe';
    final myShare = _myShare;

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
                                      ? (myShare?.id == share.id
                                          ? 'You (host)'
                                          : 'Host')
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
                  if (group.status == 'collecting' && myShare != null) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _paying ? null : _payMyShare,
                      style: FilledButton.styleFrom(
                        backgroundColor: WtvaColors.accentPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            WtvaColors.accentPurple.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        _paying ? _payStage : 'Pay ${_money(myShare.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  if (group.status == 'collecting' &&
                      myShare == null &&
                      group.shares.any((s) => s.status == 'pending')) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Your share is already paid, or sign in with the invited email to pay.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: WtvaColors.neutral300,
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
