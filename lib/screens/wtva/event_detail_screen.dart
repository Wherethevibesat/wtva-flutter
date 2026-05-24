import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/ticket_tier.dart';
import '../../services/event_ticket_checkout_service.dart';
import '../../services/events_repository.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/wtva_feedback.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<_EventDetailData> _future;
  String? _busyTierId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<_EventDetailData> _load() async {
    final event = await EventsRepository.instance.getPublishedEvent(widget.eventId);
    final tiers = await EventsRepository.instance.listTicketTiers(widget.eventId);
    final userId = UserService().currentUser?.id;
    final registeredTier = userId != null
        ? await EventsRepository.instance.getUserRegistrationTierName(widget.eventId, userId)
        : null;
    return _EventDetailData(event: event, tiers: tiers, registeredTierName: registeredTier);
  }

  Future<void> _selectTier(EventTicketTierRecord tier) async {
    final userId = UserService().currentUser?.id;
    if (userId == null) {
      showWtvaSnack(context, 'Sign in to RSVP or buy tickets', icon: Icons.error_outline);
      return;
    }

    setState(() => _busyTierId = tier.id);
    try {
      final checkout = EventTicketCheckoutService.instance;
      if (tier.priceCents <= 0) {
        await checkout.freeRsvp(eventId: widget.eventId, tier: tier);
      } else {
        await checkout.purchaseTicket(eventId: widget.eventId, tier: tier);
      }
      if (!mounted) return;
      showWtvaSnack(
        context,
        tier.priceCents <= 0 ? 'RSVP confirmed' : 'Ticket confirmed',
        icon: Icons.check_circle_outline,
      );
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      showWtvaSnack(context, e.toString(), icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _busyTierId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Event', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<_EventDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          final event = data?.event;
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }
          final when = event.endsAt != null
              ? '${DateFormat('EEE, MMM d · h:mm a').format(event.startsAt.toLocal())} – ${DateFormat('h:mm a').format(event.endsAt!.toLocal())}'
              : DateFormat('EEE, MMM d · h:mm a').format(event.startsAt.toLocal());
          final tiers = data?.tiers ?? const [];
          final registered = data?.registeredTierName;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(when, style: const TextStyle(color: WtvaColors.neutral300)),
              if (event.neighborhood != null) ...[
                const SizedBox(height: 4),
                Text(event.neighborhood!, style: const TextStyle(color: WtvaColors.neutral300)),
              ],
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(event.description!),
              ],
              if (registered != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: WtvaColors.dark400,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: WtvaColors.neutral300),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You\'re registered ($registered)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (tiers.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Tickets & RSVP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                const Text(
                  'Free RSVP is always available when listed.',
                  style: TextStyle(color: WtvaColors.neutral300, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...tiers.map(
                  (tier) {
                    final busy = _busyTierId == tier.id;
                    return Card(
                      color: WtvaColors.dark400,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(tier.name),
                        subtitle: Text(formatTierPrice(tier.priceCents)),
                        trailing: ElevatedButton(
                          onPressed: busy || _busyTierId != null ? null : () => _selectTier(tier),
                          child: Text(
                            busy
                                ? '…'
                                : tier.priceCents <= 0
                                    ? 'Free RSVP'
                                    : 'Get ticket',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EventDetailData {
  const _EventDetailData({
    required this.event,
    required this.tiers,
    this.registeredTierName,
  });

  final WtvaEventRecord? event;
  final List<EventTicketTierRecord> tiers;
  final String? registeredTierName;
}
