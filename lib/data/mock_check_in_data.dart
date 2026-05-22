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
  static const nearby = [
    NearbyVenueCheckIn(id: '3', name: 'The Dream Club', distanceMiles: 0.2),
    NearbyVenueCheckIn(id: '4', name: 'Dream Land', distanceMiles: 0.3),
    NearbyVenueCheckIn(id: '1', name: 'Barbarella Pizza', distanceMiles: 0.8),
    NearbyVenueCheckIn(id: '2', name: "Joe's Strip Bar", distanceMiles: 1.1),
  ];
}
