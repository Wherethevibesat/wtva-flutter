import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/ticket_tier.dart';
import '../../services/customer_portal_api.dart';
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
        await checkout.purchaseTicket(
          context: context,
          eventId: widget.eventId,
          tier: tier,
        );
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
      body: FutureBuilder<_EventDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          final event = data?.event;
          if (event == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Event')),
              body: const Center(child: Text('Event not found')),
            );
          }

          final when = event.endsAt != null
              ? '${DateFormat('EEE, MMM d · h:mm a').format(event.startsAt.toLocal())} – ${DateFormat('h:mm a').format(event.endsAt!.toLocal())}'
              : DateFormat('EEE, MMM d · h:mm a').format(event.startsAt.toLocal());
          final tiers = data?.tiers ?? const [];
          final registered = data?.registeredTierName;
          final imageUrl = event.imageUrl ??
              'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1200&q=80';
          final topInset = MediaQuery.paddingOf(context).top;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260 + topInset,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: WtvaColors.dark300),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: topInset + 8,
                        left: 12,
                        child: _CircleBtn(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: WtvaColors.dark500,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            _Chip(event.eventType),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          when,
                          style: const TextStyle(
                            color: WtvaColors.neutral200,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (event.neighborhood != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.neighborhood!,
                            style: const TextStyle(color: WtvaColors.neutral300),
                          ),
                        ],
                        if (event.venueName != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 18, color: WtvaColors.accentPurple),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  event.venueName!,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (event.description != null && event.description!.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            event.description!,
                            style: const TextStyle(
                              color: WtvaColors.neutral200,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        const Text(
                          'What to expect',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        _ExpectGrid(event: event, when: when),
                        if (event.venueName != null) ...[
                          const SizedBox(height: 22),
                          const Text(
                            'At the venue',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          _VenueTeaser(
                            name: event.venueName!,
                            subtitle: [
                              event.eventType,
                              if (event.neighborhood != null) event.neighborhood!,
                            ].join(' · '),
                            imageUrl: imageUrl,
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (registered != null)
                          _RegisteredCard(tierName: registered)
                        else if (tiers.isNotEmpty) ...[
                          const Text(
                            'Tickets & RSVP',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Free RSVP is always available when listed.',
                            style: TextStyle(color: WtvaColors.neutral300, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ...tiers.map((tier) {
                            final busy = _busyTierId == tier.id;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: WtvaColors.dark400,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: WtvaColors.night200),
                              ),
                              child: ListTile(
                                title: Text(tier.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(formatTierPrice(tier.priceCents)),
                                trailing: ElevatedButton(
                                  onPressed: busy || _busyTierId != null
                                      ? null
                                      : () => _selectTier(tier),
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
                          }),
                        ] else ...[
                          _InterestCard(
                            title: 'Get updates for this night',
                            subtitle:
                                'No tickets listed yet — leave your email and we’ll ping you when RSVP or VIP opens.',
                            source: 'notify_me',
                            eventId: widget.eventId,
                            eventTitle: event.title,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _InterestCard(
                          title: 'Tip a night',
                          subtitle: 'Want something else on the calendar? Tell us the vibe.',
                          source: 'tip_a_night',
                          eventId: widget.eventId,
                          eventTitle: event.title,
                          showVibes: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: WtvaColors.neutral50, size: 20),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: WtvaColors.night200),
        borderRadius: BorderRadius.circular(999),
        color: WtvaColors.dark400,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _ExpectGrid extends StatelessWidget {
  const _ExpectGrid({required this.event, required this.when});
  final WtvaEventRecord event;
  final String when;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.music_note_rounded, 'Vibe', event.eventType),
      (Icons.schedule_rounded, 'When', when),
      (
        Icons.place_outlined,
        'Where',
        [event.venueName, event.neighborhood].whereType<String>().join(' · ').ifEmpty('Houston'),
      ),
      (Icons.auto_awesome, 'Good to know', 'Check venue for hours & VIP'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WtvaColors.dark400,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: WtvaColors.night200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.$1, size: 14, color: WtvaColors.accentPurple),
                    const SizedBox(width: 6),
                    Text(
                      item.$2.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    item.$3,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

class _VenueTeaser extends StatelessWidget {
  const _VenueTeaser({
    required this.name,
    required this.subtitle,
    required this.imageUrl,
  });

  final String name;
  final String subtitle;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WtvaColors.night200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 88,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: WtvaColors.dark300),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hours, VIP & check-in on venue page',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: WtvaColors.accentPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisteredCard extends StatelessWidget {
  const _RegisteredCard({required this.tierName});
  final String tierName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WtvaColors.night200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: WtvaColors.accentGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "You're registered ($tierName)",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestCard extends StatefulWidget {
  const _InterestCard({
    required this.title,
    required this.subtitle,
    required this.source,
    required this.eventId,
    required this.eventTitle,
    this.showVibes = false,
  });

  final String title;
  final String subtitle;
  final String source;
  final String eventId;
  final String eventTitle;
  final bool showVibes;

  @override
  State<_InterestCard> createState() => _InterestCardState();
}

class _InterestCardState extends State<_InterestCard> {
  static const _vibes = [
    'Afrobeats',
    'Happy Hour',
    'Rooftop',
    'Live Music',
    'VIP',
  ];

  final _email = TextEditingController();
  final _name = TextEditingController();
  final _note = TextEditingController();
  String? _vibe;
  bool _loading = false;
  bool _done = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showWtvaSnack(context, 'Enter a valid email', icon: Icons.error_outline);
      return;
    }
    if (widget.showVibes && (_vibe == null || _vibe!.isEmpty) && _note.text.trim().isEmpty) {
      showWtvaSnack(context, 'Pick a vibe or add a note', icon: Icons.error_outline);
      return;
    }

    setState(() => _loading = true);
    try {
      await CustomerPortalApi.instance.submitEventInterest(
        email: email,
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        vibe: _vibe,
        source: widget.source,
        eventId: widget.eventId,
        city: 'Houston, TX',
      );
      if (!mounted) return;
      setState(() {
        _done = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showWtvaSnack(context, e.toString(), icon: Icons.error_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: WtvaColors.dark400,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: WtvaColors.night200),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: WtvaColors.accentPurple),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Got it — we’ll follow up when there’s a match.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WtvaColors.night200),
        boxShadow: WtvaColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(widget.subtitle, style: const TextStyle(color: WtvaColors.neutral200, fontSize: 13)),
          if (widget.showVibes) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in _vibes)
                  ChoiceChip(
                    label: Text(v),
                    selected: _vibe == v,
                    onSelected: (_) => setState(() => _vibe = _vibe == v ? null : v),
                    selectedColor: WtvaColors.accentPurple.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: _vibe == v ? WtvaColors.accentPurple : WtvaColors.neutral200,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Email'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Name (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: widget.showVibes ? 'Tip details' : 'Anything else? (optional)',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: WtvaColors.buttonGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  _loading
                      ? '…'
                      : widget.showVibes
                          ? 'Send tip'
                          : 'Notify me',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: WtvaColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
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
