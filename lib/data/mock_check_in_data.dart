class NearbyVenueCheckIn {
  final String id;
  final String name;
  final double distanceMiles;

  const NearbyVenueCheckIn({
    required this.id,
    required this.name,
    required this.distanceMiles,
  });
}

class MockCheckInData {
  /// Prefer [nearbyFromStore] — no hardcoded venue IDs.
  static const List<NearbyVenueCheckIn> nearby = [];
}
