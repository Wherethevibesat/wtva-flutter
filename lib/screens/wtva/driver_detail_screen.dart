import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/customer_portal_config.dart';
import '../../services/drivers_repository.dart';
import '../../theme/figma_theme.dart';

class DriverDetailScreen extends StatefulWidget {
  const DriverDetailScreen({super.key, required this.companyId});

  final String companyId;

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  late Future<DriverCompanyDetail?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = DriversRepository.instance.getPublishedCompany(widget.companyId);
  }

  String _formatPrice(int cents) {
    if (cents % 100 == 0) return '\$${cents ~/ 100}';
    return '\$${(cents / 100).toStringAsFixed(2)}';
  }

  String _packageLabel(DriverPackageRecord pkg) {
    if (pkg.label.trim().isNotEmpty) return pkg.label.trim();
    final hours = pkg.durationHours;
    final h = hours == hours.roundToDouble() ? hours.toInt().toString() : hours.toString();
    return '${h}h';
  }

  Future<void> _openBookingOnWeb() async {
    final base = CustomerPortalConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/drivers/${widget.companyId}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open booking page')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: FutureBuilder<DriverCompanyDetail?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final company = snapshot.data;
          if (company == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Driver listing not available.',
                    style: TextStyle(color: WtvaColors.neutral300),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            );
          }

          final allPackages = company.vehicles.expand((v) => v.packages).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: WtvaColors.dark500,
                foregroundColor: WtvaColors.neutral50,
                flexibleSpace: FlexibleSpaceBar(
                  background: company.imageUrl != null && company.imageUrl!.isNotEmpty
                      ? Image.network(
                          company.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _heroPlaceholder(),
                        )
                      : _heroPlaceholder(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.companyName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (company.city != null && company.city!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          company.city!,
                          style: const TextStyle(
                            color: WtvaColors.neutral300,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (company.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          company.description,
                          style: const TextStyle(
                            color: WtvaColors.neutral200,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (company.contactPhone != null && company.contactPhone!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Contact: ${company.contactPhone}',
                          style: const TextStyle(color: WtvaColors.neutral300, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Fleet & packages',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (company.vehicles.isEmpty)
                        const Text(
                          'No packages listed yet.',
                          style: TextStyle(color: WtvaColors.neutral300),
                        )
                      else
                        ...company.vehicles.map((vehicle) => _VehicleSection(
                              vehicle: vehicle,
                              formatPrice: _formatPrice,
                              packageLabel: _packageLabel,
                            )),
                      if (allPackages.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _openBookingOnWeb,
                            style: FilledButton.styleFrom(
                              backgroundColor: WtvaColors.accentPurple,
                              foregroundColor: WtvaColors.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Book on website',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Online booking with pickup details is available on wherethevibesat.com.',
                          style: TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: WtvaColors.dark300,
      child: const Center(
        child: Icon(Icons.directions_car_outlined, size: 64, color: WtvaColors.neutral300),
      ),
    );
  }
}

class _VehicleSection extends StatelessWidget {
  const _VehicleSection({
    required this.vehicle,
    required this.formatPrice,
    required this.packageLabel,
  });

  final DriverVehicleRecord vehicle;
  final String Function(int cents) formatPrice;
  final String Function(DriverPackageRecord pkg) packageLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WtvaColors.night200.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vehicle.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          if (vehicle.capacity != null)
            Text(
              'Up to ${vehicle.capacity} passengers',
              style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
            ),
          if (vehicle.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              vehicle.description,
              style: const TextStyle(fontSize: 13, color: WtvaColors.neutral300),
            ),
          ],
          const SizedBox(height: 10),
          ...vehicle.packages.map(
            (pkg) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          packageLabel(pkg),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (pkg.description.isNotEmpty)
                          Text(
                            pkg.description,
                            style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    formatPrice(pkg.priceCents),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
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
  }
}
