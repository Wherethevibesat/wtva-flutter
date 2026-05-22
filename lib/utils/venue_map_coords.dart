import 'package:latlong2/latlong.dart';

import '../models/venue.dart';

/// Houston center — default map focus.
const houstonCenter = LatLng(29.7604, -95.3698);

/// Stable pin position even when venue rows lack lat/lng in the database.
LatLng mapPositionForVenue(Venue venue, int index) {
  if (venue.latitude != null && venue.longitude != null) {
    return LatLng(venue.latitude!, venue.longitude!);
  }
  // Spread pins near downtown Houston when coords are missing.
  final offset = index * 0.012;
  return LatLng(houstonCenter.latitude + offset * 0.6, houstonCenter.longitude - offset);
}
