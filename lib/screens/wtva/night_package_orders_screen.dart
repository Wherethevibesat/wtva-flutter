import 'package:flutter/material.dart';
import '../../services/night_package_checkout_service.dart';
import '../../services/night_packages_repository.dart';
import '../../theme/figma_theme.dart';
import '../../utils/vibe_copy.dart';
import 'night_package_success_screen.dart';
import 'vibe_split_waiting_screen.dart';

class NightPackageOrdersScreen extends StatefulWidget {
  const NightPackageOrdersScreen({super.key});

  @override
  State<NightPackageOrdersScreen> createState() =>
      _NightPackageOrdersScreenState();
}

class _NightPackageOrdersScreenState extends State<NightPackageOrdersScreen> {
  late Future<_MyPlansData> _future;
  String? _payingOrderId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MyPlansData> _load() async {
    final repo = NightPackagesRepository.instance;
    final results = await Future.wait([
      repo.listOpenPaymentGroups(),
      repo.listMyOrders(),
    ]);
    return _MyPlansData(
      openSplits: results[0] as List<OpenVibeSplitRecord>,
      orders: results[1] as List<NightPackageOrderRecord>,
    );
  }

  String _money(int cents) {
    final dollars = cents / 100;
    return '\$${dollars.toStringAsFixed(dollars.truncateToDouble() == dollars ? 0 : 2)}';
  }

  String? _formatStartsOn(String? iso) {
    if (iso == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(iso)) {
      return null;
    }
    final parts = iso.split('-');
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final year = int.parse(parts[0]);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[month - 1]} $day, $year';
  }

  String _formatExpires(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final m = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, $h:$m $ampm';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'requested':
        return 'Waiting on venues';
      case 'awaiting_payment':
        return 'Ready to pay';
      case 'expired':
        return 'Request expired';
      case 'cancelled':
        return 'Cancelled';
      case 'paid':
        return 'Your vibe';
      default:
        return status;
    }
  }

  String _stopStatusLabel(String status) {
    return status.replaceAll('_', ' ');
  }

  Future<void> _payAwaitingOrder(NightPackageOrderRecord order) async {
    final packageId = order.packageId;
    if (packageId == null || packageId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing package for this plan')),
      );
      return;
    }
    setState(() => _payingOrderId = order.id);
    try {
      final result = await NightPackageCheckoutService.instance.purchase(
        context: context,
        packageId: packageId,
        partySize: order.partySize,
        stopOfferIds: const [],
        startsOn: order.startsOn ?? '',
        orderId: order.id,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NightPackageSuccessScreen(
            packageName: result.packageName,
            amount: result.amount,
            partySize: result.partySize,
            stopCount: result.stopCount,
            startsOnLabel: _formatStartsOn(order.startsOn),
          ),
        ),
      );
      setState(() {
        _future = _load();
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError ? e.message : 'Checkout failed';
      if (msg == 'Payment cancelled') return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _payingOrderId = null);
    }
  }

  Widget _openSplitCard(OpenVibeSplitRecord split) {
    final startsLabel = _formatStartsOn(split.startsOn);
    final statusLine = split.role == 'host'
        ? '${split.paidCount}/${split.payerCount} paid'
        : (split.mySharePending
            ? 'your share unpaid'
            : 'your share paid · waiting on others');
    final cta = split.mySharePending && split.myAmountCents != null
        ? 'Finish payment · ${_money(split.myAmountCents!)}'
        : 'Open waiting room';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: WtvaColors.accentPurple.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IN PROGRESS · SPLIT PAY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: WtvaColors.accentPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            split.packageTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: WtvaColors.neutral50,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (startsLabel != null) 'Starting $startsLabel',
              '${split.partySize} guests',
              statusLine,
            ].join(' · '),
            style: const TextStyle(
              fontSize: 13,
              color: WtvaColors.neutral300,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VibeSplitWaitingScreen(
                      inviteToken: split.inviteToken,
                      packageTitle: split.packageTitle,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: WtvaColors.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(cta),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(NightPackageOrderRecord order) {
    final startsLabel = _formatStartsOn(order.startsOn);
    final isPaid = order.isPaid;
    final paying = _payingOrderId == order.id;
    final eyebrow = _statusLabel(order.status).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.isAwaitingPayment
              ? WtvaColors.accentPurple.withValues(alpha: 0.55)
              : WtvaColors.night200.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: order.isExpired
                  ? WtvaColors.neutral300
                  : WtvaColors.accentPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.packageTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: WtvaColors.neutral50,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (startsLabel != null) 'Starting $startsLabel',
              'Ref ${order.confirmationCode}',
              '${order.partySize} guests',
              _money(order.totalCents),
              if (order.isRequested && order.expiresAt != null)
                'expires ${_formatExpires(order.expiresAt!)}',
            ].join(' · '),
            style: const TextStyle(
              fontSize: 13,
              color: WtvaColors.neutral300,
            ),
          ),
          if (order.isRequested) ...[
            const SizedBox(height: 10),
            const Text(
              'Venues confirm first. You’ll pay the full total once everyone accepts.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: WtvaColors.neutral300,
              ),
            ),
          ],
          if (order.stops.isNotEmpty) ...[
            const SizedBox(height: 18),
            ...order.stops.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final isLast = i == order.stops.length - 1;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: WtvaColors.accentPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: WtvaColors.accentPurple
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.scheduledLabel ?? 'Stop ${i + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: WtvaColors.accentPurple,
                              ),
                            ),
                            Text(
                              s.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: WtvaColors.neutral50,
                              ),
                            ),
                            if (s.venueName != null)
                              Text(
                                s.venueName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: WtvaColors.neutral300,
                                ),
                              ),
                            if (!isPaid) ...[
                              const SizedBox(height: 4),
                              Text(
                                _stopStatusLabel(s.status),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: WtvaColors.neutral300,
                                ),
                              ),
                            ] else if (s.redemptionCode.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                s.redemptionCode,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: WtvaColors.accentPurple,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (order.isAwaitingPayment) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: paying ? null : () => _payAwaitingOrder(order),
                style: FilledButton.styleFrom(
                  backgroundColor: WtvaColors.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  paying
                      ? 'Opening checkout…'
                      : 'Pay now · ${_money(order.totalCents)}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        title: const Text(VibeCopy.myPlans),
      ),
      body: FutureBuilder<_MyPlansData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ??
              const _MyPlansData(openSplits: [], orders: []);
          final openSplits = data.openSplits;
          final orders = data.orders;
          if (openSplits.isEmpty && orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No plans yet.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Browse curated vibes to book your night.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: WtvaColors.neutral300),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Open requests, splits, and booked itineraries show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: WtvaColors.neutral300,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final children = <Widget>[];
          if (openSplits.isNotEmpty) {
            children.add(
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Finish payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: WtvaColors.neutral50,
                  ),
                ),
              ),
            );
            for (final split in openSplits) {
              children.add(_openSplitCard(split));
              children.add(const SizedBox(height: 16));
            }
          }
          if (orders.isNotEmpty) {
            if (openSplits.isNotEmpty) {
              children.add(
                const Padding(
                  padding: EdgeInsets.only(bottom: 10, top: 4),
                  child: Text(
                    'Your vibes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: WtvaColors.neutral50,
                    ),
                  ),
                ),
              );
            }
            for (var i = 0; i < orders.length; i++) {
              children.add(_orderCard(orders[i]));
              if (i < orders.length - 1) {
                children.add(const SizedBox(height: 16));
              }
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _load();
              });
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: children,
            ),
          );
        },
      ),
    );
  }
}

class _MyPlansData {
  const _MyPlansData({
    required this.openSplits,
    required this.orders,
  });

  final List<OpenVibeSplitRecord> openSplits;
  final List<NightPackageOrderRecord> orders;
}
