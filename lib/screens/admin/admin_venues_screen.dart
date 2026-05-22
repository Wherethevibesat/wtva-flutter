import 'package:flutter/material.dart';
import 'admin_edit_venue_screen.dart';

class AdminVenuesScreen extends StatefulWidget {
  const AdminVenuesScreen({super.key});

  @override
  State<AdminVenuesScreen> createState() => _AdminVenuesScreenState();
}

class _AdminVenuesScreenState extends State<AdminVenuesScreen> {
  String _searchQuery = '';
  String? _selectedFilter;

  // Mock venues data
  final List<Map<String, dynamic>> _venues = [
    {
      'id': 'v1',
      'name': 'The Post Oak',
      'type': 'Nightclub',
      'neighborhood': 'Galleria/Uptown',
      'isFeatured': true,
      'status': 'active',
      'owner': 'John Doe',
    },
    {
      'id': 'v2',
      'name': 'Z on 23',
      'type': 'Rooftop',
      'neighborhood': 'Downtown',
      'isFeatured': true,
      'status': 'active',
      'owner': 'Jane Smith',
    },
    {
      'id': 'v3',
      'name': 'Clé Houston',
      'type': 'Lounge',
      'neighborhood': 'Midtown',
      'isFeatured': false,
      'status': 'active',
      'owner': 'Mike Johnson',
    },
  ];

  List<Map<String, dynamic>> get _filteredVenues {
    var filtered = List<Map<String, dynamic>>.from(_venues);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((venue) {
        return venue['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            venue['neighborhood'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedFilter != null) {
      switch (_selectedFilter) {
        case 'featured':
          filtered = filtered.where((v) => v['isFeatured'] == true).toList();
          break;
        case 'active':
          filtered = filtered.where((v) => v['status'] == 'active').toList();
          break;
      }
    }

    return filtered;
  }

  void _toggleFeatured(String venueId) {
    setState(() {
      final venue = _venues.firstWhere((v) => v['id'] == venueId);
      venue['isFeatured'] = !(venue['isFeatured'] as bool);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _venues.firstWhere((v) => v['id'] == venueId)['isFeatured']
              ? 'Venue featured'
              : 'Venue unfeatured',
        ),
      ),
    );
  }

  void _deleteVenue(String venueId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Venue?'),
        content: const Text('This action cannot be undone. All associated events will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _venues.removeWhere((v) => v['id'] == venueId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Venue deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Venues'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search venues...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedFilter == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Featured'),
                        selected: _selectedFilter == 'featured',
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? 'featured' : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Active'),
                        selected: _selectedFilter == 'active',
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? 'active' : null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Venues List
          Expanded(
            child: _filteredVenues.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No venues found',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredVenues.length,
                    itemBuilder: (context, index) {
                      final venue = _filteredVenues[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.business,
                              color: theme.primaryColor,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  venue['name'],
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              if (venue['isFeatured'])
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Featured',
                                        style: TextStyle(
                                          color: Colors.amber.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${venue['type']} • ${venue['neighborhood']}'),
                              Text('Owner: ${venue['owner']}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      venue['isFeatured'] ? Icons.star_border : Icons.star,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(venue['isFeatured'] ? 'Unfeature' : 'Feature'),
                                  ],
                                ),
                                onTap: () => _toggleFeatured(venue['id']),
                              ),
                              PopupMenuItem(
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                                onTap: () async {
                                  // Wait for popup menu to close
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  if (mounted) {
                                    final updatedVenue = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminEditVenueScreen(
                                          venue: venue,
                                        ),
                                      ),
                                    );
                                    if (updatedVenue != null) {
                                      setState(() {
                                        final index = _venues.indexWhere((v) => v['id'] == venue['id']);
                                        if (index != -1) {
                                          _venues[index] = updatedVenue;
                                        }
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Venue updated successfully')),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                              PopupMenuItem(
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                                onTap: () => _deleteVenue(venue['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

