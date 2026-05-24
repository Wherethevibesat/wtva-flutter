import 'package:flutter/material.dart';
import '../../data/event_types.dart';
import '../../data/weekdays.dart';
import '../../services/neighborhoods_repository.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_select_chip.dart';

class EventsFilters {
  final String? eventType;
  final List<String> neighborhoods;

  /// [DateTime.weekday] values (1 = Monday … 7 = Sunday), local time when filtering.
  final List<int> daysOfWeek;

  const EventsFilters({
    this.eventType,
    this.neighborhoods = const [],
    this.daysOfWeek = const [],
  });

  bool get hasSelection =>
      eventType != null || neighborhoods.isNotEmpty || daysOfWeek.isNotEmpty;

  int get activeCount =>
      (eventType != null ? 1 : 0) + neighborhoods.length + daysOfWeek.length;
}

/// Event type + neighborhood filters in a bottom sheet.
class EventsFiltersSheet extends StatefulWidget {
  const EventsFiltersSheet({
    super.key,
    required this.initial,
    required this.neighborhoods,
  });

  final EventsFilters initial;
  final List<NeighborhoodRecord> neighborhoods;

  static Future<EventsFilters?> show(
    BuildContext context, {
    required EventsFilters initial,
    required List<NeighborhoodRecord> neighborhoods,
  }) {
    return showModalBottomSheet<EventsFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WtvaColors.dark400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EventsFiltersSheet(
        initial: initial,
        neighborhoods: neighborhoods,
      ),
    );
  }

  @override
  State<EventsFiltersSheet> createState() => _EventsFiltersSheetState();
}

class _EventsFiltersSheetState extends State<EventsFiltersSheet> {
  late String? _eventType;
  late List<String> _neighborhoods;
  late List<int> _daysOfWeek;

  @override
  void initState() {
    super.initState();
    _eventType = widget.initial.eventType;
    _neighborhoods = List<String>.from(widget.initial.neighborhoods);
    _daysOfWeek = List<int>.from(widget.initial.daysOfWeek);
  }

  void _clearAll() {
    setState(() {
      _eventType = null;
      _neighborhoods = [];
      _daysOfWeek = [];
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (_daysOfWeek.contains(day)) {
        _daysOfWeek = _daysOfWeek.where((value) => value != day).toList();
      } else {
        _daysOfWeek = [..._daysOfWeek, day]..sort();
      }
    });
  }

  void _toggleNeighborhood(String name) {
    setState(() {
      if (_neighborhoods.contains(name)) {
        _neighborhoods = _neighborhoods.where((value) => value != name).toList();
      } else {
        _neighborhoods = [..._neighborhoods, name];
      }
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      EventsFilters(
        eventType: _eventType,
        neighborhoods: _neighborhoods,
        daysOfWeek: _daysOfWeek,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

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
                    onPressed: _clearAll,
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterSection(
                      title: 'Event type',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'All types',
                            active: _eventType == null,
                            onTap: () => setState(() => _eventType = null),
                          ),
                          for (final type in WtvaEventTypes.all)
                            _FilterChip(
                              label: type,
                              active: _eventType == type,
                              onTap: () => setState(() => _eventType = type),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FilterSection(
                      title: 'Day of week',
                      subtitle: 'Select one or more days',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'Any day',
                            active: _daysOfWeek.isEmpty,
                            onTap: () => setState(() => _daysOfWeek = []),
                          ),
                          for (final day in WtvaWeekdays.all)
                            _FilterChip(
                              label: day.shortLabel,
                              active: _daysOfWeek.contains(day.id),
                              onTap: () => _toggleDay(day.id),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FilterSection(
                      title: 'Neighborhood',
                      subtitle: 'Select one or more areas',
                      child: widget.neighborhoods.isEmpty
                          ? const Text(
                              'No neighborhoods loaded yet.',
                              style: TextStyle(color: WtvaColors.neutral300, fontSize: 13),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FilterChip(
                                  label: 'All areas',
                                  active: _neighborhoods.isEmpty,
                                  onTap: () => setState(() => _neighborhoods = []),
                                ),
                                for (final n in widget.neighborhoods)
                                  _FilterChip(
                                    label: n.name,
                                    active: _neighborhoods.contains(n.name),
                                    onTap: () => _toggleNeighborhood(n.name),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: WtvaColors.neutral50,
                    foregroundColor: WtvaColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply filters', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(color: WtvaColors.neutral300, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WtvaSelectChip(
      label: label,
      selected: active,
      onTap: onTap,
    );
  }
}
