import 'package:flutter/material.dart';
import '../../services/night_packages_repository.dart';
import '../../theme/figma_theme.dart';
import 'night_package_plan_screen.dart';

class NightPackageDetailScreen extends StatefulWidget {
  const NightPackageDetailScreen({super.key, required this.packageId});

  final String packageId;

  @override
  State<NightPackageDetailScreen> createState() =>
      _NightPackageDetailScreenState();
}

class _NightPackageDetailScreenState extends State<NightPackageDetailScreen> {
  late Future<NightPackageRecord?> _future;

  @override
  void initState() {
    super.initState();
    _future = NightPackagesRepository.instance.getPublished(widget.packageId);
  }

  String _money(int cents) {
    final dollars = cents / 100;
    return '\$${dollars.toStringAsFixed(dollars.truncateToDouble() == dollars ? 0 : 2)}';
  }

  String _slotLabel(String slot) {
    return slot
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  void _customize(NightPackageRecord pkg) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NightPackagePlanScreen(package: pkg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        title: const Text('Package'),
      ),
      body: FutureBuilder<NightPackageRecord?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final pkg = snapshot.data;
          if (pkg == null) {
            return const Center(
              child: Text(
                'Package not found',
                style: TextStyle(color: WtvaColors.neutral300),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Text(
                      pkg.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    if (pkg.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        pkg.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: WtvaColors.neutral300,
                        ),
                      ),
                    ],
                    if (pkg.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        pkg.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: WtvaColors.neutral200,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'From ${_money(pkg.subtotalCents)} / person',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    Text(
                      'Party size ${pkg.partySizeMin}–${pkg.partySizeMax}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: WtvaColors.neutral300,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your itinerary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pkg.stops.asMap().entries.map((entry) {
                      final i = entry.key;
                      final stop = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: WtvaColors.dark400,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: WtvaColors.night200.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STOP ${i + 1}${stop.scheduledLabel != null ? ' · ${stop.scheduledLabel}' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: WtvaColors.accentPurple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stop.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: WtvaColors.neutral50,
                              ),
                            ),
                            Text(
                              '${stop.venueName ?? 'Venue'} · ${_slotLabel(stop.slotType)}'
                              '${stop.arrivalWindow != null ? ' · ${stop.arrivalWindow}' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: WtvaColors.neutral300,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _money(stop.priceCents),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: WtvaColors.neutral100,
                              ),
                            ),
                            if (stop.inclusions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...stop.inclusions.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '• $item',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: WtvaColors.neutral300,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _customize(pkg),
                      style: FilledButton.styleFrom(
                        backgroundColor: WtvaColors.accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Customize & book',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
