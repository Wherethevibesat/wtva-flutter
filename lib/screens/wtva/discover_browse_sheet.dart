import 'package:flutter/material.dart';
import '../../data/event_types.dart';
import '../../services/neighborhoods_repository.dart';
import '../../theme/figma_theme.dart';
import 'events_browse_screen.dart';
import 'neighborhood_venues_screen.dart';

/// Secondary browse filters — event types and neighborhoods — in one sheet.
class DiscoverBrowseSheet extends StatefulWidget {
  const DiscoverBrowseSheet({super.key, this.initialSection});

  /// `events` or `areas` — scrolls the sheet toward that section when opened.
  final String? initialSection;

  static Future<void> show(
    BuildContext context, {
    String? initialSection,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WtvaColors.dark400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DiscoverBrowseSheet(initialSection: initialSection),
    );
  }

  @override
  State<DiscoverBrowseSheet> createState() => _DiscoverBrowseSheetState();
}

class _DiscoverBrowseSheetState extends State<DiscoverBrowseSheet> {
  final _eventsKey = GlobalKey();
  final _areasKey = GlobalKey();
  late Future<List<NeighborhoodRecord>> _neighborhoodsFuture;

  @override
  void initState() {
    super.initState();
    _neighborhoodsFuture = NeighborhoodsRepository.instance.list();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitialSection());
  }

  void _scrollToInitialSection() {
    final section = widget.initialSection;
    if (section == null) return;
    final key = section == 'areas' ? _areasKey : _eventsKey;
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _openEvents({String? eventType}) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventsBrowseScreen(initialEventType: eventType),
      ),
    );
  }

  void _openNeighborhood(String name) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NeighborhoodVenuesScreen(neighborhoodName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WtvaColors.night200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Browse',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: WtvaColors.neutral300),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KeyedSubtree(
                      key: _eventsKey,
                      child: _Section(
                        title: 'Event type',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _BrowseChip(
                              label: 'All events',
                              onTap: () => _openEvents(),
                            ),
                            for (final type in WtvaEventTypes.all)
                              _BrowseChip(
                                label: type,
                                onTap: () => _openEvents(eventType: type),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    KeyedSubtree(
                      key: _areasKey,
                      child: _Section(
                        title: 'Neighborhood',
                        child: FutureBuilder<List<NeighborhoodRecord>>(
                          future: _neighborhoodsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: WtvaColors.neutral300,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final rows = snapshot.data ?? const [];
                            if (rows.isEmpty) {
                              return const Text(
                                'No neighborhoods loaded yet.',
                                style: TextStyle(color: WtvaColors.neutral300, fontSize: 13),
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final n in rows)
                                  _BrowseChip(
                                    label: n.name,
                                    onTap: () => _openNeighborhood(n.name),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _BrowseChip extends StatelessWidget {
  const _BrowseChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: WtvaColors.dark300,
      labelStyle: const TextStyle(
        color: WtvaColors.neutral100,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onPressed: onTap,
    );
  }
}
