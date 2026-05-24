import 'package:flutter/material.dart';
import '../../data/ticket_tier.dart';
import '../../theme/figma_theme.dart';

class BusinessTicketTiersEditor extends StatefulWidget {
  const BusinessTicketTiersEditor({
    super.key,
    required this.tiers,
    required this.onChanged,
    this.enabled = true,
  });

  final List<TicketTierInput> tiers;
  final ValueChanged<List<TicketTierInput>> onChanged;
  final bool enabled;

  @override
  State<BusinessTicketTiersEditor> createState() => _BusinessTicketTiersEditorState();
}

class _BusinessTicketTiersEditorState extends State<BusinessTicketTiersEditor> {
  late List<TicketTierInput> _tiers;

  @override
  void initState() {
    super.initState();
    _tiers = normalizeTicketTiers(widget.tiers);
  }

  @override
  void didUpdateWidget(BusinessTicketTiersEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tiers != oldWidget.tiers) {
      _tiers = normalizeTicketTiers(widget.tiers);
    }
  }

  void _emit(List<TicketTierInput> next) {
    final normalized = normalizeTicketTiers(next);
    setState(() => _tiers = normalized);
    widget.onChanged(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Tickets & RSVP', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: widget.enabled
                  ? () => _emit([
                        ..._tiers,
                        const TicketTierInput(name: 'General Admission', priceCents: 2000),
                      ])
                  : null,
              child: const Text('+ Paid tier'),
            ),
          ],
        ),
        const Text(
          'Free RSVP is always the first option. Add paid tiers with name, price, and description.',
          style: TextStyle(color: WtvaColors.neutral300, fontSize: 12),
        ),
        const SizedBox(height: 8),
        ..._tiers.asMap().entries.map((entry) {
          return _TierRow(
            key: ValueKey('tier-${entry.key}-${entry.value.name}-${entry.value.priceCents}'),
            tier: entry.value,
            index: entry.key,
            enabled: widget.enabled,
            onChanged: (tier) {
              final next = [..._tiers];
              next[entry.key] = tier;
              _emit(next);
            },
            onRemove: entry.key == 0
                ? null
                : () => _emit([for (var i = 0; i < _tiers.length; i++) if (i != entry.key) _tiers[i]]),
          );
        }),
      ],
    );
  }
}

class _TierRow extends StatefulWidget {
  const _TierRow({
    super.key,
    required this.tier,
    required this.index,
    required this.enabled,
    required this.onChanged,
    this.onRemove,
  });

  final TicketTierInput tier;
  final int index;
  final bool enabled;
  final ValueChanged<TicketTierInput> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_TierRow> createState() => _TierRowState();
}

class _TierRowState extends State<_TierRow> {
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _price;

  bool get _isFree => widget.index == 0;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.tier.name);
    _description = TextEditingController(text: widget.tier.description);
    _price = TextEditingController(
      text: _isFree
          ? '0'
          : (widget.tier.priceCents / 100).toStringAsFixed(widget.tier.priceCents % 100 == 0 ? 0 : 2),
    );
  }

  @override
  void didUpdateWidget(_TierRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tier.name != widget.tier.name) {
      _name.text = widget.tier.name;
    }
    if (oldWidget.tier.description != widget.tier.description) {
      _description.text = widget.tier.description;
    }
    if (oldWidget.tier.priceCents != widget.tier.priceCents && !_isFree) {
      _price.text = (widget.tier.priceCents / 100)
          .toStringAsFixed(widget.tier.priceCents % 100 == 0 ? 0 : 2);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  void _emit({String? name, String? description, int? priceCents}) {
    widget.onChanged(
      TicketTierInput(
        name: name ?? _name.text.trim(),
        description: description ?? _description.text,
        priceCents: priceCents ?? widget.tier.priceCents,
        capacity: widget.tier.capacity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: WtvaColors.dark400,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: widget.enabled && !_isFree,
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: _isFree ? 'Free RSVP' : 'Ticket name',
                      isDense: true,
                    ),
                    onChanged: _isFree ? null : (_) => _emit(),
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    onPressed: widget.enabled ? widget.onRemove : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: widget.enabled,
              controller: _description,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: _isFree ? 'RSVP details (optional)' : 'Ticket description',
                isDense: true,
              ),
              onChanged: (_) => _emit(),
            ),
            if (!_isFree) ...[
              const SizedBox(height: 8),
              TextField(
                enabled: widget.enabled,
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price (USD)',
                  isDense: true,
                  helperText: formatTierPrice(widget.tier.priceCents),
                ),
                onChanged: (value) {
                  final dollars = double.tryParse(value) ?? 0;
                  _emit(priceCents: (dollars * 100).round());
                },
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  formatTierPrice(widget.tier.priceCents),
                  style: const TextStyle(color: WtvaColors.neutral300, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
