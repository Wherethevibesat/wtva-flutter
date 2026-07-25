import '../config/app_config.dart';
import 'supabase_bootstrap.dart';

class NightPackageStopRecord {
  const NightPackageStopRecord({
    required this.id,
    required this.offerId,
    required this.sortOrder,
    this.scheduledLabel,
    required this.title,
    required this.slotType,
    required this.priceCents,
    required this.inclusions,
    this.arrivalWindow,
    this.venueId,
    this.venueName,
    this.whyPicked = '',
    this.durationLabel,
    this.dressCode,
  });

  final String id;
  final String offerId;
  final int sortOrder;
  final String? scheduledLabel;
  final String title;
  final String slotType;
  final int priceCents;
  final List<String> inclusions;
  final String? arrivalWindow;
  final String? venueId;
  final String? venueName;
  final String whyPicked;
  final String? durationLabel;
  final String? dressCode;
}

class NightPackageRecord {
  const NightPackageRecord({
    required this.id,
    this.slug,
    required this.title,
    required this.subtitle,
    required this.description,
    this.tagline = '',
    this.imageUrl,
    required this.city,
    required this.partySizeMin,
    required this.partySizeMax,
    required this.isFeatured,
    this.templateKey,
    this.vibeTags = const [],
    required this.stops,
  });

  final String id;
  final String? slug;
  final String title;
  final String subtitle;
  final String description;
  final String tagline;
  final String? imageUrl;
  final String city;
  final int partySizeMin;
  final int partySizeMax;
  final bool isFeatured;
  final String? templateKey;
  final List<String> vibeTags;
  final List<NightPackageStopRecord> stops;

  int get subtotalCents => stops.fold(0, (sum, s) => sum + s.priceCents);

  String get pathId => (slug != null && slug!.isNotEmpty) ? slug! : id;

  String get displayTagline =>
      tagline.trim().isNotEmpty ? tagline.trim() : subtitle;
}

class ApprovedStopOfferRecord {
  const ApprovedStopOfferRecord({
    required this.id,
    required this.title,
    required this.slotType,
    required this.priceCents,
    this.arrivalWindow,
    this.venueId,
    this.venueName,
    this.description = '',
    this.whyPicked = '',
    this.scheduledLabel,
  });

  final String id;
  final String title;
  final String slotType;
  final int priceCents;
  final String? arrivalWindow;
  final String? venueId;
  final String? venueName;
  final String description;
  final String whyPicked;
  final String? scheduledLabel;
}

class NightPackageOrderStopRecord {
  const NightPackageOrderStopRecord({
    required this.title,
    required this.redemptionCode,
    this.scheduledLabel,
    this.venueName,
    this.lineTotalCents,
    this.sortOrder = 0,
  });

  final String title;
  final String redemptionCode;
  final String? scheduledLabel;
  final String? venueName;
  final int? lineTotalCents;
  final int sortOrder;
}

class NightPackageOrderRecord {
  const NightPackageOrderRecord({
    required this.id,
    required this.confirmationCode,
    required this.packageTitle,
    required this.partySize,
    required this.totalCents,
    required this.status,
    this.startsOn,
    required this.stops,
  });

  final String id;
  final String confirmationCode;
  final String packageTitle;
  final int partySize;
  final int totalCents;
  final String status;
  final String? startsOn;
  final List<NightPackageOrderStopRecord> stops;
}

/// Open split-pay group the user can finish later (My Plans).
class OpenVibeSplitRecord {
  const OpenVibeSplitRecord({
    required this.id,
    required this.inviteToken,
    required this.packageTitle,
    required this.partySize,
    required this.startsOn,
    required this.totalCents,
    required this.expiresAt,
    required this.paidCount,
    required this.payerCount,
    required this.mySharePending,
    this.myAmountCents,
    this.role,
  });

  final String id;
  final String inviteToken;
  final String packageTitle;
  final int partySize;
  final String startsOn;
  final int totalCents;
  final DateTime expiresAt;
  final int paidCount;
  final int payerCount;
  final bool mySharePending;
  final int? myAmountCents;
  final String? role;
}

/// Published Curated Vibes from Supabase (`night_packages`).
class NightPackagesRepository {
  NightPackagesRepository._();
  static final NightPackagesRepository instance = NightPackagesRepository._();

  static const _select = '''
    id, slug, title, subtitle, description, tagline, image_url, city,
    party_size_min, party_size_max, is_featured, sort_order,
    template_key, vibe_tags,
    stops:night_package_stops(
      id, sort_order, scheduled_label,
      stop_offer:package_stop_offers(
        id, title, slot_type, price_cents, inclusions, arrival_window,
        why_picked, duration_label, dress_code,
        status, is_active,
        venue:venues(id, name)
      )
    )
  ''';

  Future<List<NightPackageRecord>> listPublished({int limit = 40}) async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) {
      return const [];
    }
    final client = SupabaseBootstrap.client;
    if (client == null) return const [];

    try {
      final rows = await client
          .from('night_packages')
          .select(_select)
          .eq('status', 'published')
          .order('sort_order')
          .limit(limit);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(_fromRow)
          .where((p) => p.stops.isNotEmpty)
          .toList();
    } catch (_) {
      // Fallback if storytelling columns not migrated yet.
      try {
        final rows = await client
            .from('night_packages')
            .select('''
              id, slug, title, subtitle, description, image_url, city,
              party_size_min, party_size_max, is_featured, sort_order,
              stops:night_package_stops(
                id, sort_order, scheduled_label,
                stop_offer:package_stop_offers(
                  id, title, slot_type, price_cents, inclusions, arrival_window,
                  status, is_active, venue:venues(id, name)
                )
              )
            ''')
            .eq('status', 'published')
            .order('sort_order')
            .limit(limit);
        return (rows as List)
            .cast<Map<String, dynamic>>()
            .map(_fromRow)
            .where((p) => p.stops.isNotEmpty)
            .toList();
      } catch (_) {
        return const [];
      }
    }
  }

  Future<NightPackageRecord?> getPublished(String idOrSlug) async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) {
      return null;
    }
    final client = SupabaseBootstrap.client;
    if (client == null) return null;

    try {
      final uuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(idOrSlug);

      var query =
          client.from('night_packages').select(_select).eq('status', 'published');
      query = uuid ? query.eq('id', idOrSlug) : query.eq('slug', idOrSlug);

      final row = await query.maybeSingle();
      if (row == null) return null;
      return _fromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<double> fetchCommissionPct() async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) {
      return 15;
    }
    final client = SupabaseBootstrap.client;
    if (client == null) return 15;
    try {
      final row = await client
          .from('platform_settings')
          .select('night_package_commission_pct')
          .eq('id', 1)
          .maybeSingle();
      return (row?['night_package_commission_pct'] as num?)?.toDouble() ?? 15;
    } catch (_) {
      return 15;
    }
  }

  Future<List<OpenVibeSplitRecord>> listOpenPaymentGroups() async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) {
      return const [];
    }
    final client = SupabaseBootstrap.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return const [];

    try {
      final rows = await client
          .from('vibe_payment_groups')
          .select('''
            id, invite_token, party_size, starts_on, total_cents, status,
            expires_at, payer_count, host_user_id,
            package:night_packages(title),
            shares:vibe_payment_shares(id, status, role, amount_cents, user_id)
          ''')
          .eq('status', 'collecting')
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at', ascending: false);

      final now = DateTime.now().toUtc();
      final out = <OpenVibeSplitRecord>[];
      for (final row in (rows as List).cast<Map<String, dynamic>>()) {
        final expiresRaw = row['expires_at'] as String?;
        final expiresAt = expiresRaw == null
            ? null
            : DateTime.tryParse(expiresRaw)?.toUtc();
        if (expiresAt == null || !expiresAt.isAfter(now)) continue;

        final isHost = row['host_user_id'] == userId;
        final shares =
            ((row['shares'] as List?) ?? const []).cast<Map<String, dynamic>>();
        Map<String, dynamic>? myShare;
        for (final s in shares) {
          if (s['user_id'] == userId) {
            myShare = s;
            break;
          }
        }
        if (!isHost && myShare == null) continue;

        final pkgRaw = row['package'];
        final packageTitle = pkgRaw is Map
            ? (pkgRaw['title'] as String? ?? 'Your vibe')
            : 'Your vibe';
        final paidCount =
            shares.where((s) => s['status'] == 'paid').length;
        final role = (myShare?['role'] as String?) ?? (isHost ? 'host' : null);

        out.add(
          OpenVibeSplitRecord(
            id: row['id'] as String,
            inviteToken: row['invite_token'] as String? ?? '',
            packageTitle: packageTitle,
            partySize: (row['party_size'] as num?)?.toInt() ?? 1,
            startsOn: row['starts_on'] as String? ?? '',
            totalCents: (row['total_cents'] as num?)?.toInt() ?? 0,
            expiresAt: expiresAt,
            paidCount: paidCount,
            payerCount: (row['payer_count'] as num?)?.toInt() ?? shares.length,
            mySharePending: myShare != null
                ? myShare['status'] == 'pending'
                : isHost,
            myAmountCents: (myShare?['amount_cents'] as num?)?.toInt(),
            role: role,
          ),
        );
      }
      return out.where((g) => g.inviteToken.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<NightPackageOrderRecord>> listMyOrders() async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) {
      return const [];
    }
    final client = SupabaseBootstrap.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return const [];

    try {
      final rows = await client
          .from('night_package_orders')
          .select('''
            id, confirmation_code, party_size, starts_on, total_cents, status,
            package:night_packages(title),
            stops:night_package_order_stops(
              title, redemption_code, scheduled_label, sort_order,
              line_total_cents, venue:venues(name)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (rows as List).cast<Map<String, dynamic>>().map((row) {
        final pkgRaw = row['package'];
        final packageTitle = pkgRaw is Map
            ? (pkgRaw['title'] as String? ?? 'Your vibe')
            : 'Your vibe';
        final stopRows = (row['stops'] as List?) ?? const [];
        final stops = stopRows.cast<Map<String, dynamic>>().map((s) {
          final venueRaw = s['venue'];
          final venueName =
              venueRaw is Map ? venueRaw['name'] as String? : null;
          return NightPackageOrderStopRecord(
            title: s['title'] as String? ?? 'Stop',
            redemptionCode: s['redemption_code'] as String? ?? '',
            scheduledLabel: s['scheduled_label'] as String?,
            venueName: venueName,
            lineTotalCents: (s['line_total_cents'] as num?)?.toInt(),
            sortOrder: (s['sort_order'] as num?)?.toInt() ?? 0,
          );
        }).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return NightPackageOrderRecord(
          id: row['id'] as String,
          confirmationCode: row['confirmation_code'] as String? ?? '',
          packageTitle: packageTitle,
          partySize: (row['party_size'] as num?)?.toInt() ?? 1,
          totalCents: (row['total_cents'] as num?)?.toInt() ?? 0,
          status: row['status'] as String? ?? 'paid',
          startsOn: row['starts_on'] as String?,
          stops: stops,
        );
      }).toList();
    } catch (_) {
      // starts_on may be missing pre-migration
      try {
        final rows = await client
            .from('night_package_orders')
            .select('''
              id, confirmation_code, party_size, total_cents, status,
              package:night_packages(title),
              stops:night_package_order_stops(
                title, redemption_code, scheduled_label, sort_order,
                line_total_cents, venue:venues(name)
              )
            ''')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        return (rows as List).cast<Map<String, dynamic>>().map((row) {
          final pkgRaw = row['package'];
          final packageTitle = pkgRaw is Map
              ? (pkgRaw['title'] as String? ?? 'Your vibe')
              : 'Your vibe';
          final stopRows = (row['stops'] as List?) ?? const [];
          final stops = stopRows.cast<Map<String, dynamic>>().map((s) {
            final venueRaw = s['venue'];
            final venueName =
                venueRaw is Map ? venueRaw['name'] as String? : null;
            return NightPackageOrderStopRecord(
              title: s['title'] as String? ?? 'Stop',
              redemptionCode: s['redemption_code'] as String? ?? '',
              scheduledLabel: s['scheduled_label'] as String?,
              venueName: venueName,
              lineTotalCents: (s['line_total_cents'] as num?)?.toInt(),
              sortOrder: (s['sort_order'] as num?)?.toInt() ?? 0,
            );
          }).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return NightPackageOrderRecord(
            id: row['id'] as String,
            confirmationCode: row['confirmation_code'] as String? ?? '',
            packageTitle: packageTitle,
            partySize: (row['party_size'] as num?)?.toInt() ?? 1,
            totalCents: (row['total_cents'] as num?)?.toInt() ?? 0,
            status: row['status'] as String? ?? 'paid',
            stops: stops,
          );
        }).toList();
      } catch (_) {
        return const [];
      }
    }
  }

  Future<List<ApprovedStopOfferRecord>> listApprovedStops({
    String? slotType,
    List<String> excludeIds = const [],
  }) async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) {
      return const [];
    }
    final client = SupabaseBootstrap.client;
    if (client == null) return const [];

    try {
      var query = client.from('package_stop_offers').select(
            'id, title, description, slot_type, price_cents, arrival_window, why_picked, venue:venues(id, name)',
          ).eq('status', 'approved').eq('is_active', true);

      if (slotType != null && slotType.isNotEmpty) {
        query = query.eq('slot_type', slotType);
      }

      final rows = await query.order('slot_type').order('title');
      final exclude = excludeIds.toSet();
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .where((row) => !exclude.contains(row['id']))
          .map((row) {
            final venueRaw = row['venue'];
            final venueId =
                venueRaw is Map ? venueRaw['id'] as String? : null;
            final venueName =
                venueRaw is Map ? venueRaw['name'] as String? : null;
            return ApprovedStopOfferRecord(
              id: row['id'] as String,
              title: row['title'] as String? ?? 'Stop',
              description: row['description'] as String? ?? '',
              slotType: row['slot_type'] as String? ?? 'other',
              priceCents: (row['price_cents'] as num?)?.toInt() ?? 0,
              arrivalWindow: row['arrival_window'] as String?,
              whyPicked: row['why_picked'] as String? ?? '',
              venueId: venueId,
              venueName: venueName,
            );
          })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  NightPackageRecord _fromRow(Map<String, dynamic> row) {
    final rawStops = (row['stops'] as List?) ?? const [];
    final stops = <NightPackageStopRecord>[];
    for (final raw in rawStops) {
      final s = Map<String, dynamic>.from(raw as Map);
      final offerRaw = s['stop_offer'];
      if (offerRaw is! Map) continue;
      final offer = Map<String, dynamic>.from(offerRaw);
      if (offer['status'] != 'approved' || offer['is_active'] == false) {
        continue;
      }
      final venueRaw = offer['venue'];
      final venueId = venueRaw is Map ? venueRaw['id'] as String? : null;
      final venueName = venueRaw is Map ? venueRaw['name'] as String? : null;
      final inclusions = (offer['inclusions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      stops.add(
        NightPackageStopRecord(
          id: s['id'] as String,
          offerId: offer['id'] as String? ?? s['id'] as String,
          sortOrder: (s['sort_order'] as num?)?.toInt() ?? 0,
          scheduledLabel: s['scheduled_label'] as String?,
          title: offer['title'] as String? ?? 'Stop',
          slotType: offer['slot_type'] as String? ?? 'other',
          priceCents: (offer['price_cents'] as num?)?.toInt() ?? 0,
          inclusions: inclusions,
          arrivalWindow: offer['arrival_window'] as String?,
          venueId: venueId,
          venueName: venueName,
          whyPicked: offer['why_picked'] as String? ?? '',
          durationLabel: offer['duration_label'] as String?,
          dressCode: offer['dress_code'] as String?,
        ),
      );
    }
    stops.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return NightPackageRecord(
      id: row['id'] as String,
      slug: row['slug'] as String?,
      title: row['title'] as String? ?? 'Vibe',
      subtitle: row['subtitle'] as String? ?? '',
      description: row['description'] as String? ?? '',
      tagline: row['tagline'] as String? ?? '',
      imageUrl: row['image_url'] as String?,
      city: row['city'] as String? ?? 'houston',
      partySizeMin: (row['party_size_min'] as num?)?.toInt() ?? 1,
      partySizeMax: (row['party_size_max'] as num?)?.toInt() ?? 20,
      isFeatured: row['is_featured'] == true,
      templateKey: row['template_key'] as String?,
      vibeTags: _stringList(row['vibe_tags']),
      stops: stops,
    );
  }
}
