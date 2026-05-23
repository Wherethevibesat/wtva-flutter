import '../data/houston_neighborhoods.dart';
import 'supabase_bootstrap.dart';
import 'supabase_data.dart';

class NeighborhoodRecord {
  final String name;
  final String slug;
  final String? description;

  const NeighborhoodRecord({
    required this.name,
    required this.slug,
    this.description,
  });
}

/// Loads canonical neighborhoods from Supabase (Houston first).
class NeighborhoodsRepository {
  NeighborhoodsRepository._();
  static final NeighborhoodsRepository instance = NeighborhoodsRepository._();

  static const defaultCity = 'Houston';

  List<NeighborhoodRecord>? _cache;

  Future<List<NeighborhoodRecord>> list({
    String city = defaultCity,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null) return _cache!;

    if (SupabaseData.enabled) {
      final client = SupabaseBootstrap.client;
      if (client != null) {
        try {
          final rows = await client
              .from('neighborhoods')
              .select('name, slug, description')
              .eq('city', city)
              .eq('is_active', true)
              .order('sort_order')
              .order('name');
          if (rows.isNotEmpty) {
            _cache = [
              for (final raw in rows)
                NeighborhoodRecord(
                  name: (raw as Map<String, dynamic>)['name'] as String,
                  slug: raw['slug'] as String,
                  description: raw['description'] as String?,
                ),
            ];
            return _cache!;
          }
        } catch (_) {
          // fall through to static list
        }
      }
    }

    _cache = [
      for (final name in HoustonNeighborhoods.neighborhoods)
        NeighborhoodRecord(
          name: name,
          slug: HoustonNeighborhoods.slugify(name),
        ),
    ];
    return _cache!;
  }

  Future<List<String>> listNames({String city = defaultCity}) async {
    final rows = await list(city: city);
    return rows.map((r) => r.name).toList();
  }

  void clearCache() => _cache = null;
}
