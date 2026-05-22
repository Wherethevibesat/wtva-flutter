import 'package:flutter/material.dart';
import '../../data/mock_discover_data.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';

class PromotionEditorScreen extends StatefulWidget {
  const PromotionEditorScreen({super.key});

  @override
  State<PromotionEditorScreen> createState() => _PromotionEditorScreenState();
}

class _PromotionEditorScreenState extends State<PromotionEditorScreen> {
  String? _venueId;
  final _title = TextEditingController(text: '50% OFF Entry Fee');
  final _description = TextEditingController(
    text: 'Valid tonight before 11 PM. Show app at door.',
  );
  DateTime _ends = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Create promotion', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _venueId ?? MockDiscoverData.venues.first.id,
            decoration: const InputDecoration(labelText: 'Venue'),
            dropdownColor: WtvaColors.dark400,
            items: [
              for (final v in MockDiscoverData.venues)
                DropdownMenuItem(value: v.id, child: Text(v.name)),
            ],
            onChanged: (v) => setState(() => _venueId = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Promotion title'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ends', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${_ends.month}/${_ends.day}/${_ends.year}',
              style: const TextStyle(color: WtvaColors.neutral300),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _ends,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _ends = picked);
            },
          ),
          const SizedBox(height: 32),
          WtvaGradientButton(
            label: 'Publish promotion',
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Promotion published (demo)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
