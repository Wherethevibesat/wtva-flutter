import 'package:flutter/material.dart';
import '../../data/mock_check_in_history_data.dart';
import '../../services/ranking_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_empty_state.dart';
import 'venue_detail_screen.dart';

class WtvaCheckInHistoryScreen extends StatefulWidget {
  const WtvaCheckInHistoryScreen({super.key});

  @override
  State<WtvaCheckInHistoryScreen> createState() => _WtvaCheckInHistoryScreenState();
}

class _WtvaCheckInHistoryScreenState extends State<WtvaCheckInHistoryScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    RankingService.instance.onUserChanged().whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ranking = RankingService.instance;
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Check-in history', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: WtvaColors.accentPurple))
          : ListenableBuilder(
              listenable: ranking,
              builder: (context, _) {
                final entries = ranking.checkInHistory;
                if (entries.isEmpty) {
                  return WtvaEmptyState(
                    icon: Icons.history,
                    title: 'No check-ins yet',
                    subtitle: 'Check in at venues to build your nightlife history.',
                    actionLabel: 'Back',
                    onAction: () => Navigator.pop(context),
                  );
                }
                return RefreshIndicator(
                  color: WtvaColors.accentPurple,
                  onRefresh: () async {
                    await RankingService.instance.onUserChanged();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _HistoryTile(entry: entries[i]),
                  ),
                );
              },
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final CheckInHistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (entry.venueId.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VenueDetailScreen(venueId: entry.venueId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: entry.imageUrl.isEmpty
                    ? Container(
                        width: 56,
                        height: 56,
                        color: WtvaColors.dark300,
                        child: const Icon(Icons.storefront_outlined),
                      )
                    : Image.network(
                        entry.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: WtvaColors.dark300,
                          child: const Icon(Icons.storefront_outlined),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.venueName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      entry.dateLabel,
                      style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                    ),
                    if (entry.hasPost)
                      const Text(
                        'Posted with photos',
                        style: TextStyle(fontSize: 11, color: WtvaColors.lavender300),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}
