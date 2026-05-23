import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/event_types.dart';
import '../../widgets/wtva/neighborhood_dropdown.dart';

class AdminEditEventScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const AdminEditEventScreen({
    super.key,
    required this.event,
  });

  @override
  State<AdminEditEventScreen> createState() => _AdminEditEventScreenState();
}

class _AdminEditEventScreenState extends State<AdminEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _venueNameController;
  late TextEditingController _promoterNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _eventType;
  String? _neighborhood;
  bool _isFeatured = false;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event['title'] ?? '');
    _venueNameController = TextEditingController(text: widget.event['venueName'] ?? '');
    _promoterNameController = TextEditingController(text: widget.event['promoterName'] ?? '');
    _descriptionController = TextEditingController(text: widget.event['description'] ?? '');
    _imageUrlController = TextEditingController(text: widget.event['imageUrl'] ?? '');
    
    _selectedDate = widget.event['date'] is DateTime 
        ? widget.event['date'] as DateTime
        : DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    _eventType = widget.event['eventType'] ?? WtvaEventTypes.defaultType;
    _neighborhood = widget.event['neighborhood'] ?? 'Downtown';
    _isFeatured = widget.event['isFeatured'] ?? false;
    _status = widget.event['status'] ?? 'active';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueNameController.dispose();
    _promoterNameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      // Return updated event data
      Navigator.pop(context, {
        'id': widget.event['id'],
        'title': _titleController.text,
        'venueName': _venueNameController.text,
        'promoterName': _promoterNameController.text,
        'description': _descriptionController.text,
        'imageUrl': _imageUrlController.text,
        'date': _selectedDate,
        'eventType': _eventType,
        'neighborhood': _neighborhood,
        'isFeatured': _isFeatured,
        'status': _status,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an event title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Venue Name
            TextFormField(
              controller: _venueNameController,
              decoration: const InputDecoration(
                labelText: 'Venue Name *',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a venue name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Promoter Name
            TextFormField(
              controller: _promoterNameController,
              decoration: const InputDecoration(
                labelText: 'Promoter Name *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a promoter name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date and Time
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('MMM d, y').format(_selectedDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time *',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Event Type
            DropdownButtonFormField<String>(
              value: _eventType,
              decoration: const InputDecoration(
                labelText: 'Event Type *',
                prefixIcon: Icon(Icons.category),
              ),
              items: WtvaEventTypes.all
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _eventType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an event type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Neighborhood
            NeighborhoodDropdown(
              value: _neighborhood,
              onChanged: (value) {
                setState(() {
                  _neighborhood = value;
                });
              },
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
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _status = value ?? 'active';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Featured Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Featured Event'),
                subtitle: const Text('Show this event prominently'),
                value: _isFeatured,
                onChanged: (value) {
                  setState(() {
                    _isFeatured = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveEvent,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
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



