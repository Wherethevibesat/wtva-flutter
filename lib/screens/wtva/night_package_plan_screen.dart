import 'package:flutter/material.dart';
import '../../services/night_package_checkout_service.dart';
import '../../services/night_packages_repository.dart';
import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';
import '../../utils/vibe_copy.dart';
import '../../widgets/wtva/venue_preview_sheet.dart';
import '../../widgets/wtva/vibe_flow_steps.dart';
import 'concierge_sheet.dart';
import 'night_package_success_screen.dart';
import 'vibe_split_waiting_screen.dart';

class NightPackagePlanScreen extends StatefulWidget {
  const NightPackagePlanScreen({super.key, required this.package});

  final NightPackageRecord package;

  @override
  State<NightPackagePlanScreen> createState() => _NightPackagePlanScreenState();
}

class _NightPackagePlanScreenState extends State<NightPackagePlanScreen> {
  late List<ApprovedStopOfferRecord> _stops;
  late int _partySize;
  late DateTime _startsOn;
  List<ApprovedStopOfferRecord> _catalog = const [];
  bool _loadingCatalog = true;
  bool _checkingOut = false;
  double _commissionPct = 15;
  int? _infoIndex;
  /// 0 = Build, 1 = Pay
  int _step = 0;
  /// solo = pay full total; split = multi-payer group
  String _payMode = 'solo';
  int _payerCount = 2;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startsOn = DateTime(today.year, today.month, today.day);
    _stops = widget.package.stops
        .map(
          (s) => ApprovedStopOfferRecord(
            id: s.offerId,
            title: s.title,
            slotType: s.slotType,
            priceCents: s.priceCents,
            arrivalWindow: s.arrivalWindow,
            venueId: s.venueId,
            venueName: s.venueName,
            whyPicked: s.whyPicked,
            scheduledLabel: s.scheduledLabel,
          ),
        )
        .toList();
    _partySize = widget.package.partySizeMin;
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final repo = NightPackagesRepository.instance;
    final rows = await repo.listApprovedStops();
    final pct = await repo.fetchCommissionPct();
    if (!mounted) return;
    setState(() {
      _catalog = rows;
      _commissionPct = pct;
      _loadingCatalog = false;
    });
  }

  String _money(int cents) {
    final dollars = cents / 100;
    return '\$${dollars.toStringAsFixed(dollars.truncateToDouble() == dollars ? 0 : 2)}';
  }

  String get _startsOnIso {
    final y = _startsOn.year.toString().padLeft(4, '0');
    final m = _startsOn.month.toString().padLeft(2, '0');
    final d = _startsOn.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get _startsOnLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[_startsOn.month - 1]} ${_startsOn.day}, ${_startsOn.year}';
  }

  int get _unitSubtotal => _stops.fold(0, (sum, s) => sum + s.priceCents);

  int get _subtotal => _unitSubtotal * _partySize;

  int get _serviceFee => ((_subtotal * _commissionPct) / 100).round();

  int get _total => _subtotal + _serviceFee;

  double get _perPerson => _total / 100 / _partySize.clamp(1, 999);

  int get _splitShareCents {
    final n = _payerCount.clamp(2, 20);
    final base = _total ~/ n;
    final remainder = _total - base * n;
    return base + remainder; // host share (first)
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startsOn.isBefore(first) ? first : _startsOn,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
      helpText: 'Start date',
      builder: (context, child) {
        // App surfaces are light (dark400 = white); ColorScheme.dark made
        // day numbers white-on-white.
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: WtvaColors.accentPurple,
              onPrimary: WtvaColors.onPrimary,
              surface: WtvaColors.dark400,
              onSurface: WtvaColors.neutral50,
              onSurfaceVariant: WtvaColors.neutral200,
              outline: WtvaColors.night200,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: WtvaColors.dark400,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: WtvaColors.dark400,
              headerBackgroundColor: WtvaColors.accentPurple,
              headerForegroundColor: WtvaColors.onPrimary,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return WtvaColors.neutral300;
                }
                if (states.contains(WidgetState.selected)) {
                  return WtvaColors.onPrimary;
                }
                return WtvaColors.neutral50;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return WtvaColors.onPrimary;
                }
                return WtvaColors.accentPurple;
              }),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return WtvaColors.onPrimary;
                }
                return WtvaColors.neutral50;
              }),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _startsOn = picked);
  }

  Future<void> _openPicker({required String mode, int? index}) async {
    final slot = mode == 'swap' && index != null ? _stops[index].slotType : null;
    final selected = _stops.map((s) => s.id).toSet();
    final options = _catalog.where((o) {
      if (mode == 'add' && selected.contains(o.id)) return false;
      if (mode == 'swap' && index != null && o.id == _stops[index].id) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        if (slot == null) return a.title.compareTo(b.title);
        final aSame = a.slotType == slot ? 0 : 1;
        final bSame = b.slotType == slot ? 0 : 1;
        if (aSame != bSame) return aSame.compareTo(bSame);
        return a.title.compareTo(b.title);
      });

    final picked = await showModalBottomSheet<ApprovedStopOfferRecord>(
      context: context,
      backgroundColor: WtvaColors.dark400,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          mode == 'swap'
                              ? 'Change experience'
                              : 'Add experience',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: WtvaColors.neutral50,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: WtvaColors.night200),
                if (_loadingCatalog)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (options.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No other approved experiences yet.',
                        style: TextStyle(color: WtvaColors.neutral300),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: WtvaColors.night200,
                      ),
                      itemBuilder: (context, i) {
                        final o = options[i];
                        return ListTile(
                          title: Text(
                            o.title,
                            style: const TextStyle(
                              color: WtvaColors.neutral50,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: VenueNameButton(
                            venueId: o.venueId,
                            name: o.venueName ?? 'Place',
                          ),
                          trailing: TextButton(
                            onPressed: () => Navigator.pop(context, o),
                            child: const Text(VibeCopy.changeStop),
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(height: 1, color: WtvaColors.night200),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ConciergeSheet.show(context);
                  },
                  child: const Text(
                    'Ask Concierge',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: WtvaColors.accentPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    setState(() {
      if (mode == 'swap' && index != null) {
        final keptLabel = _stops[index].scheduledLabel;
        _stops[index] = ApprovedStopOfferRecord(
          id: picked.id,
          title: picked.title,
          slotType: picked.slotType,
          priceCents: picked.priceCents,
          arrivalWindow: picked.arrivalWindow,
          venueId: picked.venueId,
          venueName: picked.venueName,
          whyPicked: picked.whyPicked,
          scheduledLabel: keptLabel ?? picked.scheduledLabel,
        );
      } else {
        _stops = [..._stops, picked];
      }
    });
  }

  Future<void> _checkout() async {
    if (_stops.isEmpty || _checkingOut) return;

    // Checkout needs a real Supabase JWT (dummy/guest sessions cannot pay).
    final ok = await AccountGate.requireSignIn(
      context,
      requireSupabaseSession: true,
      message:
          'Sign in to book your vibe — we’ll keep your plan ready after you log in.',
    );
    if (!ok || !mounted) return;

    setState(() => _checkingOut = true);
    try {
      if (_payMode == 'split') {
        final result =
            await NightPackageCheckoutService.instance.startSplitAndPayHost(
          packageId: widget.package.id,
          partySize: _partySize,
          stopOfferIds: _stops.map((s) => s.id).toList(),
          startsOn: _startsOnIso,
          payerCount: _payerCount,
        );
        if (!mounted) return;
        if (result.status == 'group_paid' || result.status == 'paid') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => NightPackageSuccessScreen(
                packageName: widget.package.title,
                amount: result.group.total,
                partySize: _partySize,
                stopCount: _stops.length,
                startsOnLabel: _startsOnLabel,
              ),
            ),
          );
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VibeSplitWaitingScreen(
              inviteToken: result.group.inviteToken,
              inviteUrl: result.group.inviteUrl,
              packageTitle: widget.package.title,
            ),
          ),
        );
        return;
      }

      final result = await NightPackageCheckoutService.instance.purchase(
        packageId: widget.package.id,
        partySize: _partySize,
        stopOfferIds: _stops.map((s) => s.id).toList(),
        startsOn: _startsOnIso,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NightPackageSuccessScreen(
            packageName: result.packageName,
            amount: result.amount,
            partySize: result.partySize,
            stopCount: result.stopCount,
            startsOnLabel: _startsOnLabel,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError ? e.message : 'Checkout failed';
      if (msg == 'Payment cancelled') return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        title: Text(_step == 0 ? VibeCopy.buildYourVibe : 'Pay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          VibeFlowSteps(step: _step + 1),
          Expanded(child: _step == 0 ? _buildStep() : _payStep()),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                widget.package.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: WtvaColors.neutral50,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _MiniField(
              label: 'Start date',
              value: _startsOnLabel,
              onTap: _pickDate,
            ),
            const SizedBox(width: 8),
            _MiniField(
              label: 'Party',
              value: '$_partySize',
              onTap: () async {
                final n = await showModalBottomSheet<int>(
                  context: context,
                  backgroundColor: WtvaColors.dark400,
                  builder: (context) {
                    return SafeArea(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (var i = widget.package.partySizeMin;
                              i <= widget.package.partySizeMax;
                              i++)
                            ListTile(
                              title: Text(
                                '$i guests',
                                style: const TextStyle(color: WtvaColors.neutral50),
                              ),
                              onTap: () => Navigator.pop(context, i),
                            ),
                        ],
                      ),
                    );
                  },
                );
                if (n != null) setState(() => _partySize = n);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          VibeCopy.softDateNote,
          style: TextStyle(fontSize: 12, color: WtvaColors.neutral300, height: 1.35),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WtvaColors.night200),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _stops.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: WtvaColors.night200.withValues(alpha: 0.8),
                  ),
                _BuildStopRow(
                  stop: _stops[i],
                  expanded: _infoIndex == i,
                  onToggleInfo: () {
                    final tip = _stops[i].whyPicked.trim();
                    if (tip.isEmpty) return;
                    setState(() => _infoIndex = _infoIndex == i ? null : i);
                  },
                  onChange: () => _openPicker(mode: 'swap', index: i),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _stops.length >= 12
              ? null
              : () => _openPicker(mode: 'add'),
          style: OutlinedButton.styleFrom(
            foregroundColor: WtvaColors.neutral200,
            side: BorderSide(
              color: WtvaColors.night200.withValues(alpha: 0.9),
              style: BorderStyle.solid,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            VibeCopy.addExperience,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WtvaColors.night200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _money((_perPerson * 100).round()),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: WtvaColors.neutral50,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'per person · continue to pay',
                style: TextStyle(fontSize: 13, color: WtvaColors.neutral300),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _stops.isEmpty ? null : () => setState(() => _step = 1),
                  style: FilledButton.styleFrom(
                    backgroundColor: WtvaColors.accentPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        VibeCopy.continueLabel,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _payStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const Text(
          VibeCopy.yourVibe,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: WtvaColors.accentPurple,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.package.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: WtvaColors.neutral50,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Starting $_startsOnLabel · ${_stops.length} experiences · $_partySize guests',
          style: const TextStyle(fontSize: 13, color: WtvaColors.neutral300),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: WtvaColors.night200.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _PayModeChip(
                  label: 'Pay myself',
                  selected: _payMode == 'solo',
                  onTap: () => setState(() => _payMode = 'solo'),
                ),
              ),
              Expanded(
                child: _PayModeChip(
                  label: 'Split with friends',
                  selected: _payMode == 'split',
                  onTap: () => setState(() => _payMode = 'split'),
                ),
              ),
            ],
          ),
        ),
        if (_payMode == 'split') ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'People paying',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: WtvaColors.neutral100,
                  ),
                ),
              ),
              IconButton(
                onPressed: _payerCount <= 2
                    ? null
                    : () => setState(() => _payerCount -= 1),
                icon: const Icon(Icons.remove_circle_outline),
                color: WtvaColors.neutral200,
              ),
              Text(
                '$_payerCount',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: WtvaColors.neutral50,
                ),
              ),
              IconButton(
                onPressed: _payerCount >= 20
                    ? null
                    : () => setState(() => _payerCount += 1),
                icon: const Icon(Icons.add_circle_outline),
                color: WtvaColors.neutral200,
              ),
            ],
          ),
          Text(
            'About ${_money(_total ~/ _payerCount.clamp(2, 20))} each · you pay ${_money(_splitShareCents)} first, then share the invite.',
            style: const TextStyle(fontSize: 13, color: WtvaColors.neutral300),
          ),
        ],
        const SizedBox(height: 20),
        ..._stops.asMap().entries.map((entry) {
          final i = entry.key;
          final stop = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: WtvaColors.accentPurple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: WtvaColors.neutral50,
                        ),
                      ),
                      VenueNameButton(
                        venueId: stop.venueId,
                        name: stop.venueName ?? 'Place',
                      ),
                    ],
                  ),
                ),
                Text(
                  _money(stop.priceCents),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: WtvaColors.neutral100,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: WtvaColors.night200.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            children: [
              _ReviewRow(label: 'Subtotal', value: _money(_subtotal)),
              const SizedBox(height: 6),
              _ReviewRow(label: 'Fees', value: _money(_serviceFee)),
              const Divider(height: 18, color: WtvaColors.night200),
              _ReviewRow(label: 'Total', value: _money(_total), bold: true),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          VibeCopy.softDateNote,
          style: TextStyle(fontSize: 12, color: WtvaColors.neutral300, height: 1.35),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _checkingOut ? null : _checkout,
            style: FilledButton.styleFrom(
              backgroundColor: WtvaColors.accentPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              _checkingOut
                  ? 'Processing…'
                  : (_payMode == 'split'
                      ? 'Pay my share & invite'
                      : VibeCopy.bookMyVibe),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _PayModeChip extends StatelessWidget {
  const _PayModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? WtvaColors.accentPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : WtvaColors.neutral300,
          ),
        ),
      ),
    );
  }
}

class _BuildStopRow extends StatelessWidget {
  const _BuildStopRow({
    required this.stop,
    required this.expanded,
    required this.onToggleInfo,
    required this.onChange,
  });

  final ApprovedStopOfferRecord stop;
  final bool expanded;
  final VoidCallback onToggleInfo;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final tip = stop.whyPicked.trim();
    final time = stopTimeLabel(
      scheduledLabel: stop.scheduledLabel,
      arrivalWindow: stop.arrivalWindow,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                slotMoodIcon(stop.slotType),
                size: 22,
                color: WtvaColors.accentPurple,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            slotTypeLabel(stop.slotType),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: WtvaColors.neutral50,
                            ),
                          ),
                        ),
                        if (tip.isNotEmpty)
                          IconButton(
                            onPressed: onToggleInfo,
                            icon: const Icon(Icons.info_outline_rounded, size: 16),
                            color: WtvaColors.neutral300,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: VenueNameButton(
                            venueId: stop.venueId,
                            name: stop.venueName ?? 'Place',
                          ),
                        ),
                        if (time.isNotEmpty)
                          Text(
                            ' · $time',
                            style: const TextStyle(
                              fontSize: 13,
                              color: WtvaColors.neutral300,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onChange,
                child: const Text('${VibeCopy.changeStop} ›'),
              ),
            ],
          ),
        ),
        if (expanded && tip.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            color: WtvaColors.dark500.withValues(alpha: 0.45),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'From the venue — ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: WtvaColors.neutral50,
                    ),
                  ),
                  TextSpan(
                    text: tip,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: WtvaColors.neutral300,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniField extends StatelessWidget {
  const _MiniField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WtvaColors.night200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: WtvaColors.neutral300),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: WtvaColors.neutral50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: bold ? WtvaColors.neutral50 : WtvaColors.neutral200,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      fontSize: bold ? 16 : 13,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
