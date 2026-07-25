import 'package:flutter/material.dart';
import '../../services/night_packages_repository.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import 'check_in_sheet.dart';
import 'concierge_sheet.dart';
import 'events_browse_screen.dart';
import 'messages_screen.dart';
import 'night_package_orders_screen.dart';
import 'night_packages_browse_screen.dart';
import 'tonight_screen.dart';
import 'wtva_profile_screen.dart';

/// Personal hub after sign-in — plans, check-in, and shortcuts.
class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({
    super.key,
    this.embedded = false,
    this.onOpenTonight,
  });

  final bool embedded;

  /// Opens the main Tonight homepage inside the app shell (preferred when embedded).
  final VoidCallback? onOpenTonight;

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  late Future<List<NightPackageOrderRecord>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = NightPackagesRepository.instance.listMyOrders();
  }

  String get _firstName {
    final name = UserService().currentUser?.name.trim() ?? '';
    if (name.isEmpty) return 'there';
    return name.split(RegExp(r'\s+')).first;
  }

  String _money(int cents) {
    final dollars = cents / 100;
    return '\$${dollars.toStringAsFixed(dollars.truncateToDouble() == dollars ? 0 : 2)}';
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersFuture = NightPackagesRepository.instance.listMyOrders();
    });
    await _ordersFuture;
  }

  void _goToTonight() {
    if (widget.onOpenTonight != null) {
      widget.onOpenTonight!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TonightScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = widget.embedded ? 100.0 : 32.0;
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        title: const Text('Dashboard'),
        actions: [
          TextButton(
            onPressed: _goToTonight,
            child: const Text('Tonight'),
          ),
          IconButton(
            tooltip: 'Account',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WtvaProfileScreen()),
              );
            },
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
          children: [
            Text(
              'Hey, $_firstName',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: WtvaColors.neutral50,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your nightlife hub — plans, check-ins, and what’s next.',
              style: TextStyle(fontSize: 14, color: WtvaColors.neutral300),
            ),
            const SizedBox(height: 16),
            Material(
              color: WtvaColors.dark400,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _goToTonight,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: WtvaColors.accentPurple.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: WtvaColors.buttonGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.nightlife_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Browse Tonight',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: WtvaColors.neutral50,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Open the main discover homepage',
                              style: TextStyle(
                                fontSize: 12,
                                color: WtvaColors.neutral300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: WtvaColors.accentPurple,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _ActionTile(
                  icon: Icons.nightlife_outlined,
                  label: 'Tonight',
                  desc: 'Main homepage',
                  onTap: _goToTonight,
                ),
                _ActionTile(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Build My Vibe',
                  desc: 'Curated plans',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NightPackagesBrowseScreen(),
                    ),
                  ),
                ),
                _ActionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Check in',
                  desc: 'Scan or confirm',
                  onTap: () => CheckInSheet.show(context),
                ),
                _ActionTile(
                  icon: Icons.auto_awesome,
                  label: 'Ask Concierge',
                  desc: 'Custom plan',
                  onTap: () => ConciergeSheet.show(context),
                ),
                _ActionTile(
                  icon: Icons.event_outlined,
                  label: 'Browse events',
                  desc: 'What’s on',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EventsBrowseScreen(),
                    ),
                  ),
                ),
                _ActionTile(
                  icon: Icons.chat_bubble_outline,
                  label: 'Messages',
                  desc: 'Inbox',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MessagesScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'My Plans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: WtvaColors.neutral50,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NightPackageOrdersScreen(),
                    ),
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<NightPackageOrderRecord>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final orders = snapshot.data ?? const [];
                if (orders.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
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
                          'No vibes booked yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: WtvaColors.neutral50,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pick a template, customize stops, and pay once.',
                          style: TextStyle(
                            fontSize: 13,
                            color: WtvaColors.neutral300,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NightPackagesBrowseScreen(),
                            ),
                          ),
                          child: const Text('Build My Vibe'),
                        ),
                      ],
                    ),
                  );
                }
                final order = orders.first;
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
                        'LATEST VIBE',
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
                          if (order.startsOn != null &&
                              RegExp(r'^\d{4}-\d{2}-\d{2}$')
                                  .hasMatch(order.startsOn!))
                            'Starting ${order.startsOn}',
                          'Code ${order.confirmationCode}',
                          '${order.partySize} guests',
                          _money(order.totalCents),
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: WtvaColors.neutral300,
                        ),
                      ),
                      if (order.stops.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...order.stops.take(3).map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.place_outlined,
                                      size: 16,
                                      color: WtvaColors.accentPurple,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s.venueName != null
                                            ? '${s.title} · ${s.venueName}'
                                            : s.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: WtvaColors.neutral50,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NightPackageOrdersScreen(),
                            ),
                          ),
                          child: const Text('Open itinerary'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: WtvaColors.night200.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: WtvaColors.buttonGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: WtvaColors.buttonShadow,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: WtvaColors.neutral50,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: WtvaColors.neutral300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
