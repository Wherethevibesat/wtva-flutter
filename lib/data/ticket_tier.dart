class TicketTierInput {
  const TicketTierInput({
    required this.name,
    this.priceCents = 0,
    this.capacity,
    this.description = '',
  });

  final String name;
  final int priceCents;
  final int? capacity;
  final String description;

  Map<String, dynamic> toJson() => {
        'name': name,
        'price_cents': priceCents,
        if (capacity != null) 'capacity': capacity,
        if (description.isNotEmpty) 'description': description,
      };
}

const freeRsvpTierName = 'Free RSVP';

List<TicketTierInput> normalizeTicketTiers(List<TicketTierInput> tiers) {
  if (tiers.isEmpty) {
    return const [TicketTierInput(name: freeRsvpTierName, priceCents: 0)];
  }

  final cleaned = tiers
      .map(
        (t) => TicketTierInput(
          name: t.name.trim().isEmpty ? freeRsvpTierName : t.name.trim(),
          priceCents: t.priceCents < 0 ? 0 : t.priceCents,
          capacity: t.capacity != null && t.capacity! > 0 ? t.capacity : null,
          description: t.description,
        ),
      )
      .toList();

  final freeIndex = cleaned.indexWhere((t) => t.priceCents == 0);
  if (freeIndex <= 0) {
    cleaned[0] = TicketTierInput(
      name: freeRsvpTierName,
      priceCents: 0,
      capacity: cleaned[0].capacity,
      description: cleaned[0].description,
    );
    return cleaned;
  }

  final free = cleaned.removeAt(freeIndex);
  return [
    TicketTierInput(name: freeRsvpTierName, priceCents: 0, capacity: free.capacity),
    ...cleaned,
  ];
}

String formatTierPrice(int cents) {
  if (cents <= 0) return 'Free';
  final dollars = cents / 100;
  return dollars == dollars.roundToDouble()
      ? '\$${dollars.toStringAsFixed(0)}'
      : '\$${dollars.toStringAsFixed(2)}';
}

class EventTicketTierRecord {
  const EventTicketTierRecord({
    required this.id,
    required this.name,
    required this.priceCents,
    this.capacity,
    this.description,
  });

  final String id;
  final String name;
  final int priceCents;
  final int? capacity;
  final String? description;
}
