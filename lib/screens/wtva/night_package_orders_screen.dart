import 'package:flutter/material.dart';
import '../../services/night_packages_repository.dart';
import '../../theme/figma_theme.dart';
import '../../utils/vibe_copy.dart';

class NightPackageOrdersScreen extends StatefulWidget {
  const NightPackageOrdersScreen({super.key});

  @override
  State<NightPackageOrdersScreen> createState() =>
      _NightPackageOrdersScreenState();
}

class _NightPackageOrdersScreenState extends State<NightPackageOrdersScreen> {
  late Future<List<NightPackageOrderRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = NightPackagesRepository.instance.listMyOrders();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        title: const Text(VibeCopy.myPlans),
      ),
      body: FutureBuilder<List<NightPackageOrderRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? const [];
          if (orders.isEmpty) {
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
                      'Itinerary, confirmation, and per-stop codes.',
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
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = NightPackagesRepository.instance.listMyOrders();
              });
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = orders[index];
                final startsLabel = _formatStartsOn(order.startsOn);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WtvaColors.dark400,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: WtvaColors.night200.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR VIBE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: WtvaColors.accentPurple,
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
                          'Confirmation ${order.confirmationCode}',
                          '${order.partySize} guests',
                          _money(order.totalCents),
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: WtvaColors.neutral300,
                        ),
                      ),
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
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          color: WtvaColors.accentPurple
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isLast ? 0 : 16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
