import 'package:flutter/material.dart';
import '../../services/night_packages_repository.dart';
import '../../theme/figma_theme.dart';
import '../../utils/vibe_copy.dart';
import '../../widgets/wtva/venue_preview_sheet.dart';
import '../../widgets/wtva/vibe_flow_steps.dart';
import 'night_package_plan_screen.dart';

/// Screen 1 — lean mood Preview (matches web `VibePreview`).
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

  void _continue(NightPackageRecord pkg) {
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
        title: const Text('Preview'),
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
                'Vibe not found',
                style: TextStyle(color: WtvaColors.neutral300),
              ),
            );
          }

          final mood = pkg.vibeTags.take(2).join(' · ');
          final moodLine = mood.isNotEmpty
              ? mood
              : (pkg.subtitle.trim().isNotEmpty
                  ? pkg.subtitle.trim()
                  : 'Curated going-out vibe');
          final tagline = pkg.displayTagline.isNotEmpty
              ? pkg.displayTagline
              : 'One unforgettable plan — customize, then book.';

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const VibeFlowSteps(step: 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '✨ $moodLine',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: WtvaColors.accentPurple,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: ' · $tagline',
                            style: const TextStyle(
                              color: WtvaColors.neutral300,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pkg.imageUrl != null && pkg.imageUrl!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 7,
                          child: Image.network(
                            pkg.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: WtvaColors.dark400),
                          ),
                        ),
                      ),
                    ],
                    if (pkg.stops.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _PreviewStopsCard(stops: pkg.stops),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: WtvaColors.dark400,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: WtvaColors.night200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _money(pkg.subtotalCents),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: WtvaColors.neutral50,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' / person',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: WtvaColors.neutral300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pkg.stops.length} experiences · one checkout',
                            style: const TextStyle(
                              fontSize: 13,
                              color: WtvaColors.neutral300,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _continue(pkg),
                              style: FilledButton.styleFrom(
                                backgroundColor: WtvaColors.accentPurple,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    VibeCopy.continueLabel,
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewStopsCard extends StatelessWidget {
  const _PreviewStopsCard({required this.stops});

  final List<NightPackageStopRecord> stops;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WtvaColors.night200),
      ),
      child: Column(
        children: [
          for (var i = 0; i < stops.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: WtvaColors.night200.withValues(alpha: 0.8)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    slotMoodIcon(stops[i].slotType),
                    size: 22,
                    color: WtvaColors.accentPurple,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slotTypeLabel(stops[i].slotType),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: WtvaColors.neutral50,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: VenueNameButton(
                                venueId: stops[i].venueId,
                                name: stops[i].venueName ?? stops[i].title,
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final time = stopTimeLabel(
                                  scheduledLabel: stops[i].scheduledLabel,
                                  arrivalWindow: stops[i].arrivalWindow,
                                );
                                if (time.isEmpty) return const SizedBox.shrink();
                                return Text(
                                  ' · $time',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: WtvaColors.neutral300,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${i + 1}/${stops.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: WtvaColors.neutral300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
