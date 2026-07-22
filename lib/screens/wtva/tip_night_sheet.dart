import 'package:flutter/material.dart';
import '../../services/customer_portal_api.dart';
import '../../theme/figma_theme.dart';
import '../../utils/wtva_feedback.dart';

class TipNightSheet {
  TipNightSheet._();

  static Future<void> show(
    BuildContext context, {
    String source = 'empty_feed',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WtvaColors.dark400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _TipNightForm(source: source),
      ),
    );
  }
}

class _TipNightForm extends StatefulWidget {
  const _TipNightForm({required this.source});
  final String source;

  @override
  State<_TipNightForm> createState() => _TipNightFormState();
}

class _TipNightFormState extends State<_TipNightForm> {
  static const _vibes = [
    'Afrobeats',
    'Happy Hour',
    'Rooftop',
    'Live Music',
    'Day Party',
    'VIP',
    'After Hours',
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
    if ((_vibe == null || _vibe!.isEmpty) && _note.text.trim().isEmpty) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: WtvaColors.night200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (_done) ...[
            const Icon(Icons.check_circle, color: WtvaColors.accentPurple, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Got it',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thanks — we’ll use this to fill the calendar.',
              style: TextStyle(color: WtvaColors.neutral200),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ] else ...[
            const Text(
              'What’s the move?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tip a night, DJ, or vibe you want to see. We’ll collect it for the calendar.',
              style: TextStyle(color: WtvaColors.neutral200, height: 1.4),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 14),
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
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Tip details'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
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
                    _loading ? '…' : 'Send tip',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: WtvaColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
