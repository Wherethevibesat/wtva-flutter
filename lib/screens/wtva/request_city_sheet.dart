import 'package:flutter/material.dart';
import '../../services/customer_portal_api.dart';
import '../../theme/figma_theme.dart';
import '../../utils/wtva_feedback.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';

class RequestCitySheet extends StatefulWidget {
  const RequestCitySheet({
    super.key,
    this.initialCity,
    this.source = 'request_form',
  });

  final String? initialCity;
  final String source;

  static Future<void> show(
    BuildContext context, {
    String? initialCity,
    String source = 'request_form',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WtvaColors.dark400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RequestCitySheet(
        initialCity: initialCity,
        source: source,
      ),
    );
  }

  @override
  State<RequestCitySheet> createState() => _RequestCitySheetState();
}

class _RequestCitySheetState extends State<RequestCitySheet> {
  late final TextEditingController _city;
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _city = TextEditingController(text: widget.initialCity ?? '');
  }

  @override
  void dispose() {
    _city.dispose();
    _email.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final city = _city.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showWtvaSnack(context, 'Enter a valid email');
      return;
    }
    if (city.isEmpty) {
      showWtvaSnack(context, 'Tell us which city');
      return;
    }
    setState(() => _busy = true);
    try {
      await CustomerPortalApi.instance.requestCity(
        email: email,
        city: city,
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        source: widget.source,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showWtvaSnack(context, "You're on the list — we'll be in touch.");
    } catch (e) {
      if (!mounted) return;
      showWtvaSnack(context, e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: WtvaColors.night200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.source == 'coming_soon'
                  ? 'Notify me at launch'
                  : 'Request a city',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              "Tell us where you want WTVA next and we'll reach out when we launch.",
              style: TextStyle(color: WtvaColors.neutral200, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            WtvaGradientButton(
              label: _busy ? 'Sending…' : 'Submit',
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
