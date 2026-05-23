import 'package:flutter/material.dart';
import '../../widgets/wtva/neighborhood_dropdown.dart';

class AdminEditVenueScreen extends StatefulWidget {
  final Map<String, dynamic> venue;

  const AdminEditVenueScreen({
    super.key,
    required this.venue,
  });

  @override
  State<AdminEditVenueScreen> createState() => _AdminEditVenueScreenState();
}

class _AdminEditVenueScreenState extends State<AdminEditVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  
  String? _venueType;
  String? _neighborhood;
  bool _isFeatured = false;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.venue['name'] ?? '');
    _addressController = TextEditingController(text: widget.venue['address'] ?? '');
    _phoneController = TextEditingController(text: widget.venue['phone'] ?? '');
    _emailController = TextEditingController(text: widget.venue['email'] ?? '');
    _websiteController = TextEditingController(text: widget.venue['website'] ?? '');
    _descriptionController = TextEditingController(text: widget.venue['description'] ?? '');
    _imageUrlController = TextEditingController(text: widget.venue['imageUrl'] ?? '');
    
    _venueType = widget.venue['type'] ?? 'Nightclub';
    _neighborhood = widget.venue['neighborhood'] ?? 'Downtown';
    _isFeatured = widget.venue['isFeatured'] ?? false;
    _status = widget.venue['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _saveVenue() {
    if (_formKey.currentState!.validate()) {
      // Return updated venue data
      Navigator.pop(context, {
        'id': widget.venue['id'],
        'name': _nameController.text,
        'type': _venueType,
        'neighborhood': _neighborhood,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'website': _websiteController.text,
        'description': _descriptionController.text,
        'imageUrl': _imageUrlController.text,
        'isFeatured': _isFeatured,
        'status': _status,
        'owner': widget.venue['owner'] ?? '',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Venue'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveVenue,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Venue Name
            TextFormField(
              controller: _nameController,
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

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Website
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                prefixIcon: Icon(Icons.language),
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
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
                title: const Text('Featured Venue'),
                subtitle: const Text('Show this venue prominently'),
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
                onPressed: _saveVenue,
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



