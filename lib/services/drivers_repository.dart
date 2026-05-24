import '../config/app_config.dart';
import 'supabase_bootstrap.dart';

class DriverCompanyRecord {
  const DriverCompanyRecord({
    required this.id,
    required this.companyName,
    required this.description,
    this.city,
    this.imageUrl,
    this.contactPhone,
  });

  final String id;
  final String companyName;
  final String description;
  final String? city;
  final String? imageUrl;
  final String? contactPhone;
}

class DriverPackageRecord {
  const DriverPackageRecord({
    required this.id,
    required this.vehicleId,
    required this.label,
    required this.durationHours,
    required this.priceCents,
    required this.description,
    this.vehicleName,
    this.vehicleCapacity,
  });

  final String id;
  final String vehicleId;
  final String label;
  final double durationHours;
  final int priceCents;
  final String description;
  final String? vehicleName;
  final int? vehicleCapacity;
}

class DriverVehicleRecord {
  const DriverVehicleRecord({
    required this.id,
    required this.name,
    required this.description,
    this.capacity,
    required this.imageUrls,
    required this.packages,
  });

  final String id;
  final String name;
  final String description;
  final int? capacity;
  final List<String> imageUrls;
  final List<DriverPackageRecord> packages;
}

class DriverCompanyDetail extends DriverCompanyRecord {
  const DriverCompanyDetail({
    required super.id,
    required super.companyName,
    required super.description,
    super.city,
    super.imageUrl,
    super.contactPhone,
    required this.vehicles,
  });

  final List<DriverVehicleRecord> vehicles;
}

/// Loads published driver companies from Supabase for customer browse.
class DriversRepository {
  DriversRepository._();
  static final DriversRepository instance = DriversRepository._();

  static const _companySelect =
      'id, company_name, description, city, image_url, contact_phone, listing_expires_at';

  bool _isListingActive(Map<String, dynamic> row) {
    final expires = row['listing_expires_at'] as String?;
    if (expires == null || expires.isEmpty) return true;
    return DateTime.parse(expires).isAfter(DateTime.now());
  }

  Future<List<DriverCompanyRecord>> listPublished({
    String? search,
    String? city,
    int limit = 60,
  }) async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) {
      return const [];
    }
    final client = SupabaseBootstrap.client;
    if (client == null) return const [];

    try {
      var query = client
          .from('driver_companies')
          .select(_companySelect)
          .eq('published', true)
          .eq('status', 'published');

      if (city != null && city.trim().isNotEmpty) {
        query = query.ilike('city', '%${city.trim()}%');
      }

      final rows = await query.order('company_name').limit(limit);
      var companies = (rows as List)
          .cast<Map<String, dynamic>>()
          .where(_isListingActive)
          .map(_companyFromRow)
          .toList();

      final q = search?.trim().toLowerCase();
      if (q != null && q.isNotEmpty) {
        companies = companies
            .where(
              (c) =>
                  c.companyName.toLowerCase().contains(q) ||
                  (c.city ?? '').toLowerCase().contains(q) ||
                  c.description.toLowerCase().contains(q),
            )
            .toList();
      }

      return companies;
    } catch (_) {
      return const [];
    }
  }

  Future<DriverCompanyDetail?> getPublishedCompany(String id) async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;

    try {
      final row = await client
          .from('driver_companies')
          .select(_companySelect)
          .eq('id', id)
          .eq('published', true)
          .eq('status', 'published')
          .maybeSingle();

      if (row == null) return null;
      if (!_isListingActive(row)) return null;

      final company = _companyFromRow(row);

      final vehicleRows = await client
          .from('driver_vehicles')
          .select('id, name, description, capacity, image_urls, sort_order')
          .eq('company_id', id)
          .eq('is_active', true)
          .order('sort_order');

      final vehicles = <DriverVehicleRecord>[];
      for (final raw in vehicleRows as List) {
        final vehicleRow = raw as Map<String, dynamic>;
        final vehicleId = vehicleRow['id'] as String;
        final packageRows = await client
            .from('driver_vehicle_packages')
            .select('id, vehicle_id, label, duration_hours, price_cents, description, sort_order')
            .eq('vehicle_id', vehicleId)
            .eq('is_active', true)
            .order('sort_order');

        final packages = (packageRows as List)
            .cast<Map<String, dynamic>>()
            .map(
              (p) => DriverPackageRecord(
                id: p['id'] as String,
                vehicleId: vehicleId,
                label: p['label'] as String? ?? '',
                durationHours: (p['duration_hours'] as num).toDouble(),
                priceCents: p['price_cents'] as int? ?? 0,
                description: p['description'] as String? ?? '',
                vehicleName: vehicleRow['name'] as String?,
                vehicleCapacity: vehicleRow['capacity'] as int?,
              ),
            )
            .toList();

        if (packages.isEmpty) continue;

        vehicles.add(
          DriverVehicleRecord(
            id: vehicleId,
            name: vehicleRow['name'] as String? ?? 'Vehicle',
            description: vehicleRow['description'] as String? ?? '',
            capacity: vehicleRow['capacity'] as int?,
            imageUrls: (vehicleRow['image_urls'] as List?)?.whereType<String>().toList() ?? const [],
            packages: packages,
          ),
        );
      }

      return DriverCompanyDetail(
        id: company.id,
        companyName: company.companyName,
        description: company.description,
        city: company.city,
        imageUrl: company.imageUrl,
        contactPhone: company.contactPhone,
        vehicles: vehicles,
      );
    } catch (_) {
      return null;
    }
  }

  DriverCompanyRecord _companyFromRow(Map<String, dynamic> row) {
    return DriverCompanyRecord(
      id: row['id'] as String,
      companyName: row['company_name'] as String? ?? 'Driver',
      description: row['description'] as String? ?? '',
      city: row['city'] as String?,
      imageUrl: row['image_url'] as String?,
      contactPhone: row['contact_phone'] as String?,
    );
  }
}
