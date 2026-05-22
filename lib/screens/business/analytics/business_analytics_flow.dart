import 'package:flutter/material.dart';
import '../../../data/mock_business_data.dart';
import '../../../theme/figma_theme.dart';
import '../../../widgets/business/business_widgets.dart';

/// #08 Analytics hub, check-ins, visitors.
class BusinessAnalyticsScreen extends StatelessWidget {
  const BusinessAnalyticsScreen({super.key});

  static const _rows = [
    ('Check-ins', '1,248', '+12%'),
    ('Unique visitors', '892', '+8%'),
    ('Avg dwell time', '2h 14m', '—'),
    ('Promo clicks', '3.4k', '+22%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Last 7 days · demo', style: TextStyle(color: WtvaColors.neutral300, fontSize: 13)),
          const SizedBox(height: 16),
          ..._rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BusinessCard(
                child: Row(
                  children: [
                    Expanded(child: Text(r.$1, style: const TextStyle(color: WtvaColors.neutral200))),
                    Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(width: 12),
                    Text(r.$3, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          BusinessMenuTile(
            icon: Icons.add_location_alt_outlined,
            title: 'Check-ins',
            subtitle: 'Who checked in at your venue',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessCheckInsScreen())),
          ),
          BusinessMenuTile(
            icon: Icons.groups_outlined,
            title: 'Visitors',
            subtitle: 'Foot traffic & demographics',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessVisitorsScreen())),
          ),
        ],
      ),
    );
  }
}

class BusinessCheckInsScreen extends StatelessWidget {
  const BusinessCheckInsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Check-ins', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: MockBusinessData.checkIns.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BusinessCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: c.avatarUrl != null ? NetworkImage(c.avatarUrl!) : null,
                    backgroundColor: WtvaColors.night200,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.guestName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(c.timeAgo, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_outline, color: WtvaColors.neutral200),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BusinessVisitorsScreen extends StatelessWidget {
  const BusinessVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Visitors', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const BusinessSectionTitle(title: 'This week'),
          const BusinessStatRow(label: 'Total visitors', value: '318'),
          const SizedBox(height: 8),
          const BusinessStatRow(label: 'New vs returning', value: '62% / 38%'),
          const SizedBox(height: 8),
          const BusinessStatRow(label: 'Peak hour', value: '10–11 PM'),
          const SizedBox(height: 24),
          const BusinessSectionTitle(title: 'Top ranks'),
          ...['Vibe Champion', 'Vibe Master', 'Vibee'].map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BusinessCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t),
                    const Text('24%', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
