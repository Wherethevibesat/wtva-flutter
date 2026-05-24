import 'package:flutter/material.dart';
import '../../services/neighborhoods_repository.dart';
import 'events_browse_screen.dart';
import 'events_filters_sheet.dart';

/// Opens the shared events filter sheet from Discover; applies to Events browse.
class DiscoverBrowseSheet {
  DiscoverBrowseSheet._();

  static Future<void> show(
    BuildContext context, {
    EventsFilters initial = const EventsFilters(),
    String? initialDate,
  }) async {
    final neighborhoods = await NeighborhoodsRepository.instance.list();
    if (!context.mounted) return;

    final result = await EventsFiltersSheet.show(
      context,
      initial: initial,
      neighborhoods: neighborhoods,
    );
    if (result == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventsBrowseScreen(
          initialFilters: result,
          initialDate: initialDate,
        ),
      ),
    );
  }
}
