/// Mirrors `web-app-customer/src/lib/cities.ts` — keep in sync when markets change.
class WtvaCity {
  const WtvaCity({
    required this.slug,
    required this.name,
    required this.state,
    required this.live,
  });

  final String slug;
  final String name;
  final String state;
  final bool live;

  /// "Houston, TX"
  String get label => '$name, $state';
}

class WtvaCities {
  WtvaCities._();

  static const List<WtvaCity> all = [
    WtvaCity(slug: 'houston', name: 'Houston', state: 'TX', live: true),
    WtvaCity(slug: 'dallas', name: 'Dallas', state: 'TX', live: false),
    WtvaCity(slug: 'atlanta', name: 'Atlanta', state: 'GA', live: false),
    WtvaCity(slug: 'miami', name: 'Miami', state: 'FL', live: false),
    WtvaCity(slug: 'washington-dc', name: 'Washington', state: 'DC', live: false),
    WtvaCity(slug: 'baltimore', name: 'Baltimore', state: 'MD', live: false),
    WtvaCity(slug: 'chicago', name: 'Chicago', state: 'IL', live: false),
    WtvaCity(slug: 'charlotte', name: 'Charlotte', state: 'NC', live: false),
    WtvaCity(slug: 'new-orleans', name: 'New Orleans', state: 'LA', live: false),
    WtvaCity(slug: 'las-vegas', name: 'Las Vegas', state: 'NV', live: false),
    WtvaCity(slug: 'new-york', name: 'New York', state: 'NY', live: false),
    WtvaCity(slug: 'los-angeles', name: 'Los Angeles', state: 'CA', live: false),
  ];

  static WtvaCity get defaultCity =>
      all.firstWhere((c) => c.live, orElse: () => all.first);

  static WtvaCity? bySlug(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    final key = slug.toLowerCase();
    for (final c in all) {
      if (c.slug == key) return c;
    }
    return null;
  }

  static WtvaCity? byLabel(String? label) {
    if (label == null || label.isEmpty) return null;
    for (final c in all) {
      if (c.label == label) return c;
    }
    return null;
  }
}
