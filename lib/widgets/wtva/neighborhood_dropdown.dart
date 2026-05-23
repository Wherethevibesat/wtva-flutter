import 'package:flutter/material.dart';
import '../../services/neighborhoods_repository.dart';
import '../../theme/figma_theme.dart';

class NeighborhoodDropdown extends StatefulWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? labelText;
  final bool required;

  const NeighborhoodDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = 'Neighborhood',
    this.required = true,
  });

  @override
  State<NeighborhoodDropdown> createState() => _NeighborhoodDropdownState();
}

class _NeighborhoodDropdownState extends State<NeighborhoodDropdown> {
  late Future<List<String>> _namesFuture;

  @override
  void initState() {
    super.initState();
    _namesFuture = NeighborhoodsRepository.instance.listNames();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _namesFuture,
      builder: (context, snapshot) {
        final names = snapshot.data ?? const [];
        final items = <String>{...names};
        if (widget.value != null && widget.value!.isNotEmpty) {
          items.add(widget.value!);
        }
        final sorted = items.toList()..sort();

        return DropdownButtonFormField<String>(
          value: widget.value != null && widget.value!.isNotEmpty ? widget.value : null,
          decoration: InputDecoration(
            labelText: widget.required ? '${widget.labelText} *' : widget.labelText,
            prefixIcon: const Icon(Icons.location_city),
          ),
          items: sorted
              .map(
                (n) => DropdownMenuItem(
                  value: n,
                  child: Text(n),
                ),
              )
              .toList(),
          onChanged: snapshot.connectionState == ConnectionState.waiting ? null : widget.onChanged,
          validator: widget.required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a neighborhood';
                  }
                  return null;
                }
              : null,
          hint: snapshot.connectionState == ConnectionState.waiting
              ? const Text('Loading neighborhoods…', style: TextStyle(color: WtvaColors.neutral300))
              : const Text('Select neighborhood'),
        );
      },
    );
  }
}
