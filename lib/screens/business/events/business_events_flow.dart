import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/event_occurrences.dart';
import '../../../data/ticket_tier.dart';
import '../../../config/app_brand.dart';
import '../../../data/event_types.dart';
import '../../../services/business_event_submission_service.dart';
import '../../../services/business_events_repository.dart';
import '../../../services/business_portal_api.dart';
import '../../../services/neighborhoods_repository.dart';
import '../../../services/platform_settings.dart';
import '../../../services/user_service.dart';
import '../../../services/venue_image_service.dart';
import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';
import '../../../widgets/business/business_widgets.dart';
import '../../../widgets/wtva/neighborhood_dropdown.dart';
import '../../../widgets/business/ticket_tiers_editor.dart';
import '../../../widgets/wtva/wtva_gradient_button.dart';

class BusinessEventsScreen extends StatefulWidget {
  const BusinessEventsScreen({super.key});

  @override
  State<BusinessEventsScreen> createState() => _BusinessEventsScreenState();
}

class _BusinessEventsScreenState extends State<BusinessEventsScreen> {
  late Future<List<BusinessEventRecord>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _eventsFuture = BusinessEventsRepository.instance.listOwnerEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Events', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<BusinessEventRecord>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            children: [
              const Text(
                'Pay the posting fee to publish instantly, or submit for admin review when allowed.',
                style: TextStyle(color: WtvaColors.neutral300, fontSize: 14),
              ),
              const SizedBox(height: 20),
              WtvaGradientButton(
                label: 'Add event',
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const BusinessCreateEventScreen()),
                  );
                  if (created == true && mounted) {
                    setState(_reload);
                  }
                },
              ),
              const SizedBox(height: 20),
              if (events.isEmpty)
                const Text('No events yet.', style: TextStyle(color: WtvaColors.neutral300))
              else
                ...events.map((event) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EventTile(event: event),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final BusinessEventRecord event;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('EEE, MMM d · h:mm a').format(event.startsAt.toLocal());
    return BusinessCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              Text(_statusLabel(event.status), style: const TextStyle(fontSize: 11, color: WtvaColors.neutral300)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${event.eventType} · $when${event.neighborhood != null ? ' · ${event.neighborhood}' : ''}',
            style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'published':
        return 'Live';
      case 'pending_review':
        return 'Pending';
      default:
        return status;
    }
  }
}

class BusinessCreateEventScreen extends StatefulWidget {
  const BusinessCreateEventScreen({super.key});

  @override
  State<BusinessCreateEventScreen> createState() => _BusinessCreateEventScreenState();
}

class _BusinessCreateEventScreenState extends State<BusinessCreateEventScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _eventType = WtvaEventTypes.defaultType;
  String? _neighborhood;
  DateTime _starts = DateTime.now().add(const Duration(days: 7)).copyWith(hour: 21, minute: 0);
  late DateTime _ends;
  final List<DateTime> _additionalDates = [];
  EventRecurrenceInput _recurrence = const EventRecurrenceInput();
  List<TicketTierInput> _ticketTiers = const [TicketTierInput(name: freeRsvpTierName, priceCents: 0)];
  String? _imageUrl;
  bool _uploadingImage = false;
  bool _submitting = false;
  late Future<List<NeighborhoodRecord>> _neighborhoodsFuture;
  late Future<EventPortalSettings> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _ends = _starts.add(const Duration(hours: 4));
    _neighborhoodsFuture = NeighborhoodsRepository.instance.list();
    _settingsFuture = BusinessEventSubmissionService.instance.loadSettings();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  BusinessEventDraft _draft() {
    return BusinessEventDraft(
      title: _title.text.trim(),
      description: _description.text.trim(),
      eventType: _eventType,
      neighborhood: _neighborhood!,
      startsAt: _starts,
      endsAt: _ends,
      additionalDates: _additionalDates,
      recurrence: _recurrence.enabled ? _recurrence : null,
      ticketTiers: _ticketTiers,
      imageUrl: _imageUrl ?? '',
    );
  }

  Future<void> _pickEventImage() async {
    final ownerId = UserService().currentUser?.id;
    if (ownerId == null) return;
    final file = await VenueImageService.instance.pickImage();
    if (file == null) return;
    setState(() => _uploadingImage = true);
    final url = await VenueImageService.instance.uploadEventImage(ownerId: ownerId, file: file);
    if (!mounted) return;
    setState(() {
      _uploadingImage = false;
      if (url != null) _imageUrl = url;
    });
    if (url == null) {
      showWtvaSnack(context, 'Image upload failed', icon: Icons.error_outline);
    }
  }

  bool _validateForm() {
    if (_title.text.trim().isEmpty || (_neighborhood?.isEmpty ?? true)) {
      showWtvaSnack(context, 'Title and neighborhood are required', icon: Icons.error_outline);
      return false;
    }
    if (!_ends.isAfter(_starts)) {
      showWtvaSnack(context, 'End must be after start', icon: Icons.error_outline);
      return false;
    }
    return true;
  }

  Future<void> _pickDateTime({required bool isEnd}) async {
    final initial = isEnd ? _ends : _starts;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    setState(() {
      final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isEnd) {
        _ends = picked;
      } else {
        _starts = picked;
        if (!_ends.isAfter(_starts)) _ends = _starts.add(const Duration(hours: 4));
      }
    });
  }

  Future<void> _addAdditionalDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _starts,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final day = DateTime(date.year, date.month, date.day);
    setState(() {
      if (!_additionalDates.any((d) => DateTime(d.year, d.month, d.day) == day)) {
        _additionalDates.add(day);
      }
    });
  }

  Future<void> _submitForReview(PlatformSettings settings, {required bool stripeConfigured}) async {
    if (!_validateForm()) return;
    setState(() => _submitting = true);
    try {
      BusinessEventSubmissionService.instance.assertReviewAllowed(
        settings,
        stripeConfigured: stripeConfigured,
      );
      await BusinessEventSubmissionService.instance.submitForReview(_draft());
      if (!mounted) return;
      showWtvaSnack(context, 'Event submitted for review', icon: Icons.check_circle_outline);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showWtvaSnack(context, e.toString(), icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _payAndPublish(EventPortalSettings portal) async {
    if (!_validateForm()) return;
    final key = portal.publishableKey;
    if (key == null || key.isEmpty) {
      showWtvaSnack(context, 'Stripe is not configured. Contact support.', icon: Icons.error_outline);
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await BusinessEventSubmissionService.instance.payAndPublish(
        draft: _draft(),
        publishableKey: key,
      );
      if (!mounted) return;
      final message = result.status == 'published' ? 'Event published' : 'Event submitted';
      showWtvaSnack(context, message, icon: Icons.check_circle_outline);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showWtvaSnack(context, e.toString(), icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewDay = DateFormat('EEE MMM d').format(_starts);
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Add event', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<EventPortalSettings>(
        future: _settingsFuture,
        builder: (context, settingsSnapshot) {
          if (settingsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final portal = settingsSnapshot.data ??
              const EventPortalSettings(settings: PlatformSettings.defaults);
          final settings = portal.settings;
          final fee = settings.eventSubmissionFee;
          final stripeConfigured = portal.publishableKey?.isNotEmpty ?? false;
          final canPay = settings.canPayToPublish && stripeConfigured;
          final canReview = settings.canFreeReview || (settings.requirePayment && fee > 0 && !stripeConfigured);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              Text(
                canReview && !canPay
                    ? 'Stripe is not configured — submit for admin review to post on ${AppBrand.name}.'
                    : canPay
                        ? 'Pay \$${fee.toStringAsFixed(2)} to publish instantly on ${AppBrand.name}, or submit for admin review${settings.canFreeReview ? '.' : ' when payment is waived.'}'
                        : 'Submit for admin review before your event goes live.',
                style: const TextStyle(color: WtvaColors.neutral300, fontSize: 13),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _submitting || _uploadingImage ? null : _pickEventImage,
                child: AspectRatio(
                  aspectRatio: 21 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: WtvaColors.dark400,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WtvaColors.dark300),
                      image: _imageUrl != null
                          ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _imageUrl == null
                        ? Center(
                            child: _uploadingImage
                                ? const CircularProgressIndicator()
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, color: WtvaColors.neutral300),
                                      SizedBox(height: 8),
                                      Text('Upload event photo', style: TextStyle(color: WtvaColors.neutral300)),
                                    ],
                                  ),
                          )
                        : null,
                  ),
                ),
              ),
              if (_imageUrl != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _submitting || _uploadingImage ? null : _pickEventImage,
                  child: Text(_uploadingImage ? 'Uploading…' : 'Replace photo'),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Event title'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _eventType,
                dropdownColor: WtvaColors.dark400,
                decoration: const InputDecoration(labelText: 'Event type'),
                items: WtvaEventTypes.all
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _eventType = value);
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<NeighborhoodRecord>>(
                future: _neighborhoodsFuture,
                builder: (context, snapshot) {
                  return NeighborhoodDropdown(
                    value: _neighborhood,
                    onChanged: (value) => setState(() => _neighborhood = value),
                  );
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start date & time', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(DateFormat('EEE, MMM d · h:mm a').format(_starts)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _submitting ? null : () => _pickDateTime(isEnd: false),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End date & time', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(DateFormat('EEE, MMM d · h:mm a').format(_ends)),
                trailing: const Icon(Icons.schedule_outlined),
                onTap: _submitting ? null : () => _pickDateTime(isEnd: true),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _submitting ? null : _addAdditionalDate,
                child: const Text('Add another date (same time)'),
              ),
              if (_additionalDates.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _additionalDates
                      .map(
                        (d) => InputChip(
                          label: Text(DateFormat('MMM d').format(d)),
                          onDeleted: _submitting ? null : () => setState(() => _additionalDates.remove(d)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repeat weekly', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _recurrence.enabled,
                onChanged: _submitting
                    ? null
                    : (value) => setState(() {
                          _recurrence = EventRecurrenceInput(
                            enabled: value,
                            byWeekday: _recurrence.byWeekday,
                            untilDate: _recurrence.untilDate,
                          );
                        }),
              ),
              if (_recurrence.enabled) ...[
                Wrap(
                  spacing: 8,
                  children: List.generate(weekdayLabels.length, (day) {
                    final active = _recurrence.byWeekday.contains(day);
                    return FilterChip(
                      label: Text(weekdayLabels[day]),
                      selected: active,
                      onSelected: _submitting
                          ? null
                          : (_) {
                              final days = [..._recurrence.byWeekday];
                              if (active) {
                                days.remove(day);
                              } else {
                                days.add(day);
                              }
                              days.sort();
                              setState(() => _recurrence = EventRecurrenceInput(
                                    enabled: true,
                                    byWeekday: days,
                                    untilDate: _recurrence.untilDate,
                                  ));
                            },
                    );
                  }),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeat until'),
                  subtitle: Text(_recurrence.untilDate.isEmpty ? 'Pick date' : _recurrence.untilDate),
                  onTap: _submitting
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _starts,
                            firstDate: _starts,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date == null) return;
                          setState(() => _recurrence = EventRecurrenceInput(
                                enabled: true,
                                byWeekday: _recurrence.byWeekday,
                                untilDate:
                                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                              ));
                        },
                ),
              ],
              BusinessTicketTiersEditor(
                tiers: _ticketTiers,
                enabled: !_submitting,
                onChanged: (tiers) => setState(() => _ticketTiers = tiers),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              Text(
                'Customer filters: $_eventType · $previewDay · ${_neighborhood ?? '—'}',
                style: const TextStyle(color: WtvaColors.neutral300, fontSize: 12),
              ),
              const SizedBox(height: 24),
              if (fee > 0)
                WtvaGradientButton(
                  label: _submitting ? 'Processing…' : 'Pay \$${fee.toStringAsFixed(2)} & publish',
                  onPressed: (_submitting || !stripeConfigured) ? null : () => _payAndPublish(portal),
                ),
              if (fee > 0 && canReview) const SizedBox(height: 12),
              if (canReview)
                OutlinedButton(
                  onPressed: _submitting ? null : () => _submitForReview(settings, stripeConfigured: stripeConfigured),
                  child: Text(_submitting ? 'Submitting…' : 'Submit event for review'),
                ),
              if (!canPay && !canReview)
                Text(
                  'Payment of \$${fee.toStringAsFixed(2)} is required to post events.',
                  style: const TextStyle(color: WtvaColors.neutral300, fontSize: 13),
                ),
            ],
          );
        },
      ),
    );
  }
}
