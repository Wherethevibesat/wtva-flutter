import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/venue.dart';
import '../../theme/figma_theme.dart';
import '../../utils/venue_map_coords.dart' show houstonCenter;

class MapVenuePin {
  final Venue venue;
  final LatLng position;

  const MapVenuePin({required this.venue, required this.position});
}

/// Map with venue pins. Uses Carto dark tiles (reliable; matches app theme).
class WtvaMapView extends StatelessWidget {
  final List<MapVenuePin> pins;
  final LatLng center;
  final double zoom;
  final void Function(Venue venue)? onVenueTap;
  final MapController? controller;

  const WtvaMapView({
    super.key,
    required this.pins,
    this.center = houstonCenter,
    this.zoom = 12.5,
    this.onVenueTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final mapController = controller ?? MapController();

    return SizedBox.expand(
      child: ColoredBox(
        color: WtvaColors.dark300,
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.wherethevibesat',
            ),
            MarkerLayer(
              markers: [
                for (final pin in pins)
                  Marker(
                    point: pin.position,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => onVenueTap?.call(pin.venue),
                      child: Container(
                        decoration: BoxDecoration(
                          color: WtvaColors.accentPurpleDeep,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
