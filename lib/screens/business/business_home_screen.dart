import 'package:flutter/material.dart';
import '../../data/mock_business_data.dart';
import '../../models/business/business_models.dart';
import '../../services/business_service.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/business/business_widgets.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';
import 'analytics/business_analytics_flow.dart';
import 'bookings/business_bookings_flow.dart';
import 'events/business_events_flow.dart';
import 'promotions/business_promotions_flow.dart';

/// #09 Main business dashboard — ads, check-ins, analytics preview.
class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BusinessService.instance,
      builder: (context, _) {
        return _HomeBody();
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = BusinessService.instance;
    final profile = svc.profile;
    final clicks = MockBusinessData.adMetrics.$1;
    final views = MockBusinessData.adMetrics.$2;
    final newCheckIns = MockBusinessData.adMetrics.$3;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.venueName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${profile.tier.label} plan · demo',
                    style: const TextStyle(color: WtvaColors.neutral300, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: WtvaColors.neutral200),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new alerts (demo)')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        WtvaGradientButton(
          label: 'Add venue event',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BusinessCreateEventScreen()),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BusinessEventsScreen()),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: WtvaColors.neutral100,
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: WtvaColors.night200),
          ),
          child: const Text('Manage events'),
        ),
        const SizedBox(height: 20),
        const BusinessSectionTitle(title: 'Your ads'),
        Row(
          children: [
            Expanded(
              child: _AdMetricCard(
                title: 'Clicks & views',
                headline: '$clicks / $views',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessAnalyticsScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AdMetricCard(
                title: 'New check-ins',
                headline: newCheckIns,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessCheckInsScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        BusinessSectionTitle(
          title: 'Check-ins',
          onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessCheckInsScreen())),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: svc.venueCheckIns.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = svc.venueCheckIns[i];
              return _CheckInCard(record: c);
            },
          ),
        ),
        const SizedBox(height: 24),
        BusinessSectionTitle(
          title: 'Analytics',
          onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessAnalyticsScreen())),
        ),
        BusinessCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _MiniStat('Check-ins', '1.2k'),
                  _MiniStat('Visitors', '892'),
                  _MiniStat('Bookings', '36'),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessAnalyticsScreen())),
                child: const Text('View insights', style: TextStyle(color: WtvaColors.neutral300, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const BusinessSectionTitle(title: 'Companies nearby'),
        ...MockBusinessData.companiesNearby.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BusinessCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: WtvaColors.night200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store, color: WtvaColors.neutral300),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(c.$2, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _LiveStreamBanner(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Live stream — demo')),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessBookingsScreen())),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WtvaColors.neutral100,
                  side: const BorderSide(color: WtvaColors.night200),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Bookings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BusinessCreatePromotionScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WtvaColors.neutral100,
                  side: const BorderSide(color: WtvaColors.night200),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('New promo'),
              ),
            ),
          ],
        ),
        if (!UserService().isLoggedIn) ...[
          const SizedBox(height: 16),
          const Text(
            'Tip: sign in to sync bookings across devices (demo).',
            style: TextStyle(fontSize: 11, color: WtvaColors.neutral300),
          ),
        ],
      ],
    );
  }
}

class _AdMetricCard extends StatelessWidget {
  final String title;
  final String headline;
  final VoidCallback onTap;

  const _AdMetricCard({required this.title, required this.headline, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
              const SizedBox(height: 8),
              Text(headline, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text('View insight', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final BusinessCheckInRecord record;

  const _CheckInCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              record.avatarUrl ?? '',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: WtvaColors.night200,
                child: Center(child: Text(record.guestName[0], style: const TextStyle(fontWeight: FontWeight.w800))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(record.guestName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(record.timeAgo, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
                const SizedBox(height: 4),
                const Text('Checked in', style: TextStyle(fontSize: 11, color: WtvaColors.neutral200)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 11, color: WtvaColors.neutral300)),
      ],
    );
  }
}

class _LiveStreamBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _LiveStreamBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WtvaColors.night200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Live stream overview', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}
