import 'package:flutter/material.dart';
import '../../services/night_packages_repository.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';
import 'night_package_detail_screen.dart';
import 'night_package_orders_screen.dart';

class NightPackagesBrowseScreen extends StatefulWidget {
  const NightPackagesBrowseScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<NightPackagesBrowseScreen> createState() =>
      _NightPackagesBrowseScreenState();
}

class _NightPackagesBrowseScreenState extends State<NightPackagesBrowseScreen> {
  late Future<List<NightPackageRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = NightPackagesRepository.instance.listPublished();
  }

  String _money(int cents) {
    final dollars = cents / 100;
    return '\$${dollars.toStringAsFixed(dollars.truncateToDouble() == dollars ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'Plan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (UserService().isGuest) {
                await AccountGate.requireSignIn(context);
                return;
              }
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NightPackageOrdersScreen()),
              );
            },
            child: const Text('My nights'),
          ),
        ],
      ),
      body: FutureBuilder<List<NightPackageRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final packages = snapshot.data ?? const [];
          if (packages.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 100),
              children: const [
                Icon(Icons.auto_awesome, size: 40, color: WtvaColors.accentPurple),
                SizedBox(height: 16),
                Text(
                  'Plan is ready',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: WtvaColors.neutral50,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'No published night packages in Supabase yet.\n\n'
                  '1. Run migrations 040 + 041 (demo seed)\n'
                  '2. Or create stops in Business → approve in Admin → publish a package\n'
                  '3. Pull to refresh here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: WtvaColors.neutral300,
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = NightPackagesRepository.instance.listPublished();
              });
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: packages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pkg = packages[index];
                return Material(
                  color: WtvaColors.dark400,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NightPackageDetailScreen(packageId: pkg.pathId),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pkg.isFeatured)
                            const Text(
                              'FEATURED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: WtvaColors.accentPurple,
                                letterSpacing: 0.6,
                              ),
                            ),
                          Text(
                            pkg.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: WtvaColors.neutral50,
                            ),
                          ),
                          if (pkg.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              pkg.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: WtvaColors.neutral300,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            '${pkg.stops.length} stops · from ${_money(pkg.subtotalCents)} / person',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: WtvaColors.neutral200,
                            ),
                          ),
                        ],
                      ),
                    ),
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
