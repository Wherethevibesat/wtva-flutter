import 'package:flutter/material.dart';
import '../../services/night_package_checkout_service.dart';
import '../../services/night_packages_repository.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';
import 'night_package_success_screen.dart';

class NightPackagePlanScreen extends StatefulWidget {
  const NightPackagePlanScreen({super.key, required this.package});

  final NightPackageRecord package;

  @override
  State<NightPackagePlanScreen> createState() => _NightPackagePlanScreenState();
}

class _NightPackagePlanScreenState extends State<NightPackagePlanScreen> {
  late List<ApprovedStopOfferRecord> _stops;
  late int _partySize;
  List<ApprovedStopOfferRecord> _catalog = const [];
  bool _loadingCatalog = true;
  bool _checkingOut = false;
  double _commissionPct = 15;

  @override
  void initState() {
    super.initState();
    _stops = widget.package.stops
        .map(
          (s) => ApprovedStopOfferRecord(
            id: s.offerId,
            title: s.title,
            slotType: s.slotType,
            priceCents: s.priceCents,
            arrivalWindow: s.arrivalWindow,
            venueName: s.venueName,
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

  int get _subtotal =>
      _stops.fold(0, (sum, s) => sum + s.priceCents) * _partySize;

  int get _serviceFee => ((_subtotal * _commissionPct) / 100).round();

  int get _total => _subtotal + _serviceFee;

  Future<void> _pickStop({required bool swap, int? index}) async {
    final selected = _stops.map((s) => s.id).toSet();
    final slot = swap && index != null ? _stops[index].slotType : null;
    final options = _catalog.where((o) {
      if (swap && index != null && o.id == _stops[index].id) return false;
      if (!swap && selected.contains(o.id)) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        if (slot == null) return a.title.compareTo(b.title);
        final aSame = a.slotType == slot ? 0 : 1;
        final bSame = b.slotType == slot ? 0 : 1;
        if (aSame != bSame) return aSame.compareTo(bSame);
        return a.title.compareTo(b.title);
      });

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other approved stops available')),
      );
      return;
    }

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
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          swap ? 'Swap stop' : 'Add experience',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: WtvaColors.neutral50,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: WtvaColors.neutral300),
                      ),
                    ],
                  ),
                ),
                if (_loadingCatalog)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final o = options[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: WtvaColors.night200.withValues(alpha: 0.6),
                            ),
                          ),
                          title: Text(
                            o.title,
                            style: const TextStyle(
                              color: WtvaColors.neutral50,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${o.venueName ?? 'Venue'} · ${_money(o.priceCents)}',
                            style: const TextStyle(color: WtvaColors.neutral300),
                          ),
                          onTap: () => Navigator.pop(context, o),
                        );
                      },
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
      if (swap && index != null) {
        _stops[index] = picked;
      } else {
        _stops = [..._stops, picked];
      }
    });
  }

  Future<void> _checkout() async {
    if (_stops.isEmpty || _checkingOut) return;
    if (UserService().isGuest) {
      final ok = await AccountGate.requireSignIn(context);
      if (!ok || !mounted) return;
    }

    setState(() => _checkingOut = true);
    try {
      final result = await NightPackageCheckoutService.instance.purchase(
        packageId: widget.package.id,
        partySize: _partySize,
        stopOfferIds: _stops.map((s) => s.id).toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NightPackageSuccessScreen(
            packageName: result.packageName,
            amount: result.amount,
            partySize: result.partySize,
            stopCount: result.stopCount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError ? e.message : 'Checkout failed';
      if (msg == 'Payment cancelled') return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
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
        title: const Text('Customize plan'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  widget.package.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: WtvaColors.neutral50,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Party size',
                      style: TextStyle(color: WtvaColors.neutral300),
                    ),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _partySize,
                      dropdownColor: WtvaColors.dark400,
                      style: const TextStyle(color: WtvaColors.neutral50),
                      items: [
                        for (var n = widget.package.partySizeMin;
                            n <= widget.package.partySizeMax;
                            n++)
                          DropdownMenuItem(value: n, child: Text('$n')),
                      ],
                      onChanged: _checkingOut
                          ? null
                          : (v) {
                              if (v == null) return;
                              setState(() => _partySize = v);
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._stops.asMap().entries.map((entry) {
                  final i = entry.key;
                  final stop = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: WtvaColors.dark400,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: WtvaColors.night200.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STOP ${i + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: WtvaColors.accentPurple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stop.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: WtvaColors.neutral50,
                          ),
                        ),
                        Text(
                          '${stop.venueName ?? 'Venue'} · ${_money(stop.priceCents)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: WtvaColors.neutral300,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _checkingOut
                                  ? null
                                  : () => _pickStop(swap: true, index: i),
                              child: const Text('Swap'),
                            ),
                            TextButton(
                              onPressed: _checkingOut || _stops.length <= 1
                                  ? null
                                  : () => setState(() {
                                        _stops = [..._stops]..removeAt(i);
                                      }),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                OutlinedButton(
                  onPressed: _checkingOut || _stops.length >= 12
                      ? null
                      : () => _pickStop(swap: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WtvaColors.neutral100,
                    side: BorderSide(
                      color: WtvaColors.night200.withValues(alpha: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Add experience'),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                        _ReviewRow(
                          label:
                              'Service fee (${_commissionPct.toStringAsFixed(_commissionPct.truncateToDouble() == _commissionPct ? 0 : 1)}%)',
                          value: _money(_serviceFee),
                        ),
                        const Divider(height: 18, color: WtvaColors.night200),
                        _ReviewRow(
                          label: 'Total',
                          value: _money(_total),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
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
                      _checkingOut ? 'Processing…' : 'Pay in app',
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
