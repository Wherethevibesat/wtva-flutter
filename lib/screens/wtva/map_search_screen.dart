import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/mock_venue_store.dart';
import '../../models/venue_detail.dart';
import '../../theme/figma_theme.dart';
import '../../utils/venue_map_coords.dart';
import '../../widgets/wtva/wtva_map_view.dart';
import 'venue_detail_screen.dart';

/// Map search with venue pins and list.
class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final _mapController = MapController();
  String _query = '';

  List<VenueDetail> get _filtered {
    final all = MockVenueStore.all;
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((d) => d.venue.name.toLowerCase().contains(q)).toList();
  }

  List<MapVenuePin> get _pins {
    return [
      for (var i = 0; i < _filtered.length; i++)
        MapVenuePin(
          venue: _filtered[i].venue,
          position: mapPositionForVenue(_filtered[i].venue, i),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Map search',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on Houston',
            onPressed: () => _mapController.move(houstonCenter, 12.5),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: WtvaMapView(
              controller: _mapController,
              center: houstonCenter,
              pins: _pins,
              onVenueTap: (v) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VenueDetailScreen(venueId: v.id),
                  ),
                );
              },
            ),
          ),
          Material(
            elevation: 12,
            color: WtvaColors.dark500,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.38,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: WtvaColors.night200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(color: WtvaColors.neutral50),
                      decoration: InputDecoration(
                        hintText: 'Search venues on map...',
                        hintStyle: const TextStyle(color: WtvaColors.neutral300),
                        prefixIcon: const Icon(Icons.search, color: WtvaColors.neutral300),
                        filled: true,
                        fillColor: WtvaColors.dark400,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No venues found',
                              style: TextStyle(color: WtvaColors.neutral300),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final detail = _filtered[index];
                              final v = detail.venue;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    v.imageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: WtvaColors.dark300,
                                      child: const Icon(
                                        Icons.storefront,
                                        color: WtvaColors.neutral300,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  v.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: WtvaColors.neutral50,
                                  ),
                                ),
                                subtitle: Text(
                                  '${v.distanceMiles} mi · ${detail.category}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: WtvaColors.neutral300,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: WtvaColors.neutral300,
                                ),
                                onTap: () {
                                  _mapController.move(
                                    mapPositionForVenue(v, index),
                                    14,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VenueDetailScreen(venueId: v.id),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
