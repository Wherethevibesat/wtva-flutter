import 'package:flutter/material.dart';
import '../../data/mock_check_in_history_data.dart';
import '../../services/ranking_service.dart';
import '../../theme/figma_theme.dart';
import 'venue_detail_screen.dart';

class WtvaCheckInHistoryScreen extends StatelessWidget {
  const WtvaCheckInHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ranking = RankingService.instance;
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Check-in history', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: ranking,
        builder: (context, _) {
          final entries = ranking.checkInHistory;
          if (entries.isEmpty) {
            return const Center(
              child: Text('No check-ins yet', style: TextStyle(color: WtvaColors.neutral300)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _HistoryTile(entry: entries[i]),
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
                child: Image.network(entry.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${entry.pointsEarned}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: WtvaColors.accentGreen,
                    ),
                  ),
                  const Text('pts', style: TextStyle(fontSize: 10, color: WtvaColors.neutral300)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
