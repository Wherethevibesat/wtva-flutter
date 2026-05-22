import 'package:flutter/material.dart';

class AdminEditVipPackageScreen extends StatefulWidget {
  final Map<String, dynamic>? package;

  const AdminEditVipPackageScreen({
    super.key,
    this.package,
  });

  @override
  State<AdminEditVipPackageScreen> createState() => _AdminEditVipPackageScreenState();
}

class _AdminEditVipPackageScreenState extends State<AdminEditVipPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _packageNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  final List<TextEditingController> _benefitControllers = [];
  
  String? _venueType;
  String? _selectedVenueId;
  String? _selectedEventId;
  String _associationType = 'venue'; // 'venue' or 'event'
  bool _isActive = true;

  // Mock data for venues and events
  final List<Map<String, dynamic>> _venues = [
    {'id': 'v1', 'name': 'The Post Oak', 'type': 'Nightclub'},
    {'id': 'v2', 'name': 'Z on 23', 'type': 'Rooftop'},
    {'id': 'v3', 'name': 'Clé Houston', 'type': 'Nightclub'},
  ];

  final List<Map<String, dynamic>> _events = [
    {'id': 'e1', 'title': 'Friday Night Vibes', 'venueName': 'The Post Oak'},
    {'id': 'e2', 'title': 'Weekend Rooftop Party', 'venueName': 'Z on 23'},
    {'id': 'e3', 'title': 'Saturday Night Live DJ Set', 'venueName': 'Clé Houston'},
  ];

  @override
  void initState() {
    super.initState();
    _packageNameController = TextEditingController(text: widget.package?['packageName'] ?? '');
    _descriptionController = TextEditingController(text: widget.package?['description'] ?? '');
    _priceController = TextEditingController(text: widget.package?['price']?.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.package?['imageUrl'] ?? '');
    
    _venueType = widget.package?['venueType'] ?? 'Nightclub';
    _selectedVenueId = widget.package?['venueId'];
    _selectedEventId = widget.package?['eventId'];
    _associationType = widget.package?['eventId'] != null ? 'event' : 'venue';
    _isActive = widget.package?['isActive'] ?? true;

    // Initialize benefits
    if (widget.package?['benefits'] != null) {
      final benefits = widget.package!['benefits'] as List;
      for (var benefit in benefits) {
        final controller = TextEditingController(text: benefit.toString());
        _benefitControllers.add(controller);
      }
    } else {
      _benefitControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    for (var controller in _benefitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addBenefit() {
    setState(() {
      _benefitControllers.add(TextEditingController());
    });
  }

  void _removeBenefit(int index) {
    setState(() {
      _benefitControllers[index].dispose();
      _benefitControllers.removeAt(index);
    });
  }

  void _savePackage() {
    if (_formKey.currentState!.validate()) {
      if (_benefitControllers.isEmpty || _benefitControllers.every((c) => c.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one benefit')),
        );
        return;
      }

      if (_associationType == 'venue' && _selectedVenueId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a venue')),
        );
        return;
      }

      if (_associationType == 'event' && _selectedEventId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an event')),
        );
        return;
      }

      final selectedVenue = _venues.firstWhere(
        (v) => v['id'] == _selectedVenueId,
        orElse: () => _venues.first,
      );

      final benefits = _benefitControllers
          .where((c) => c.text.isNotEmpty)
          .map((c) => c.text)
          .toList();

      final packageData = {
        'id': widget.package?['id'] ?? 'vip_${DateTime.now().millisecondsSinceEpoch}',
        'packageName': _packageNameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'benefits': benefits,
        'imageUrl': _imageUrlController.text,
        'venueType': _venueType,
        'venueName': _associationType == 'event'
            ? _events.firstWhere((e) => e['id'] == _selectedEventId)['venueName']
            : selectedVenue['name'],
        'venueId': _associationType == 'venue' ? _selectedVenueId : null,
        'eventId': _associationType == 'event' ? _selectedEventId : null,
        'promoterId': 'admin-1', // Current admin user ID
        'isActive': _isActive,
      };

      Navigator.pop(context, packageData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.package != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit VIP Package' : 'Create VIP Package'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePackage,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Package Name
            TextFormField(
              controller: _packageNameController,
              decoration: const InputDecoration(
                labelText: 'Package Name *',
                prefixIcon: Icon(Icons.star),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a package name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price *',
                prefixIcon: Icon(Icons.attach_money),
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Venue Type
            DropdownButtonFormField<String>(
              value: _venueType,
              decoration: const InputDecoration(
                labelText: 'Venue Type *',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'Nightclub', child: Text('Nightclub')),
                DropdownMenuItem(value: 'Lounge', child: Text('Lounge')),
                DropdownMenuItem(value: 'Bar', child: Text('Bar')),
                DropdownMenuItem(value: 'Restaurant', child: Text('Restaurant')),
                DropdownMenuItem(value: 'Speakeasy', child: Text('Speakeasy')),
                DropdownMenuItem(value: 'Rooftop', child: Text('Rooftop')),
                DropdownMenuItem(value: 'After Hours Club', child: Text('After Hours Club')),
                DropdownMenuItem(value: 'Hookah Lounge', child: Text('Hookah Lounge')),
              ],
              onChanged: (value) {
                setState(() {
                  _venueType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a venue type';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Association Type (Venue or Event)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Package Association',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'venue',
                          label: Text('Venue'),
                          icon: Icon(Icons.business),
                        ),
                        ButtonSegment(
                          value: 'event',
                          label: Text('Event'),
                          icon: Icon(Icons.event),
                        ),
                      ],
                      selected: {_associationType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _associationType = newSelection.first;
                          if (_associationType == 'venue') {
                            _selectedEventId = null;
                          } else {
                            _selectedVenueId = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_associationType == 'venue')
                      DropdownButtonFormField<String>(
                        value: _selectedVenueId,
                        decoration: const InputDecoration(
                          labelText: 'Select Venue *',
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: _venues.map<DropdownMenuItem<String>>((venue) {
                          return DropdownMenuItem<String>(
                            value: venue['id'] as String,
                            child: Text('${venue['name']} (${venue['type']})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVenueId = value;
                          });
                        },
                        validator: (value) {
                          if (_associationType == 'venue' && value == null) {
                            return 'Please select a venue';
                          }
                          return null;
                        },
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedEventId,
                        decoration: const InputDecoration(
                          labelText: 'Select Event *',
                          prefixIcon: Icon(Icons.event),
                        ),
                        items: _events.map<DropdownMenuItem<String>>((event) {
                          return DropdownMenuItem<String>(
                            value: event['id'] as String,
                            child: Text('${event['title']} at ${event['venueName']}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEventId = value;
                          });
                        },
                        validator: (value) {
                          if (_associationType == 'event' && value == null) {
                            return 'Please select an event';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Benefits
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Benefits *',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addBenefit,
                          tooltip: 'Add Benefit',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_benefitControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _benefitControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Benefit ${index + 1}',
                                  prefixIcon: const Icon(Icons.check_circle_outline),
                                ),
                              ),
                            ),
                            if (_benefitControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _removeBenefit(index),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image URL
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                prefixIcon: Icon(Icons.image),
                hintText: 'https://example.com/image.jpg',
              ),
            ),
            const SizedBox(height: 24),

            // Active Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Active Package'),
                subtitle: const Text('Make this package available for purchase'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _savePackage,
                icon: const Icon(Icons.save),
                label: Text(isEdit ? 'Save Changes' : 'Create Package'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

