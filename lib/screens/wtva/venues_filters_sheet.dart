import 'package:flutter/material.dart';
import '../../services/neighborhoods_repository.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_select_chip.dart';

class VenuesFilters {
  const VenuesFilters({this.neighborhoods = const []});

  final List<String> neighborhoods;

  bool get hasSelection => neighborhoods.isNotEmpty;
  int get activeCount => neighborhoods.length;

  VenuesFilters copyWith({List<String>? neighborhoods}) {
    return VenuesFilters(neighborhoods: neighborhoods ?? this.neighborhoods);
  }
}

/// Neighborhood filters in a bottom sheet (matches web browse filters modal).
class VenuesFiltersSheet extends StatefulWidget {
  const VenuesFiltersSheet({
    super.key,
    required this.initial,
    required this.neighborhoods,
  });

  final VenuesFilters initial;
  final List<NeighborhoodRecord> neighborhoods;

  static Future<VenuesFilters?> show(
    BuildContext context, {
    required VenuesFilters initial,
    required List<NeighborhoodRecord> neighborhoods,
  }) {
    return showModalBottomSheet<VenuesFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WtvaColors.dark400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VenuesFiltersSheet(
        initial: initial,
        neighborhoods: neighborhoods,
      ),
    );
  }

  @override
  State<VenuesFiltersSheet> createState() => _VenuesFiltersSheetState();
}

class _VenuesFiltersSheetState extends State<VenuesFiltersSheet> {
  late List<String> _neighborhoods;

  @override
  void initState() {
    super.initState();
    _neighborhoods = List<String>.from(widget.initial.neighborhoods);
  }

  void _toggle(String name) {
    setState(() {
      if (_neighborhoods.contains(name)) {
        _neighborhoods = _neighborhoods.where((v) => v != name).toList();
      } else {
        _neighborhoods = [..._neighborhoods, name];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

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
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filters',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _neighborhoods = []),
                    child: const Text('Clear all'),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Neighborhood',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select one or more areas',
                      style: TextStyle(color: WtvaColors.neutral300, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (widget.neighborhoods.isEmpty)
                      const Text(
                        'No neighborhoods loaded yet.',
                        style: TextStyle(color: WtvaColors.neutral300, fontSize: 13),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          WtvaSelectChip(
                            label: 'All areas',
                            selected: _neighborhoods.isEmpty,
                            onTap: () => setState(() => _neighborhoods = []),
                          ),
                          for (final n in widget.neighborhoods)
                            WtvaSelectChip(
                              label: n.name,
                              selected: _neighborhoods.contains(n.name),
                              onTap: () => _toggle(n.name),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: WtvaColors.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: WtvaColors.buttonShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      VenuesFilters(neighborhoods: _neighborhoods),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Apply filters',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
