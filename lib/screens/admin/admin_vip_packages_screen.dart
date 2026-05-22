import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_edit_vip_package_screen.dart';

class AdminVipPackagesScreen extends StatefulWidget {
  const AdminVipPackagesScreen({super.key});

  @override
  State<AdminVipPackagesScreen> createState() => _AdminVipPackagesScreenState();
}

class _AdminVipPackagesScreenState extends State<AdminVipPackagesScreen> {
  String _searchQuery = '';
  String? _selectedFilter;

  // Mock VIP packages data
  final List<Map<String, dynamic>> _vipPackages = [
    {
      'id': 'vip1',
      'venueName': 'The Post Oak',
      'packageName': 'VIP Table Package',
      'description': 'Premium VIP experience with bottle service and reserved table',
      'price': 299.99,
      'benefits': ['Reserved VIP table', 'Bottle service included', 'Skip the line access', 'Dedicated server', 'Complimentary mixers'],
      'imageUrl': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819',
      'venueType': 'Nightclub',
      'venueId': 'v1',
      'eventId': null,
      'promoterId': 'admin-1',
      'isActive': true,
    },
    {
      'id': 'vip2',
      'venueName': 'Z on 23',
      'packageName': 'Rooftop VIP Experience',
      'description': 'Exclusive rooftop access with premium amenities',
      'price': 199.99,
      'benefits': ['Rooftop VIP section', 'Welcome drinks', 'Priority seating', 'VIP host service'],
      'imageUrl': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7',
      'venueType': 'Rooftop',
      'venueId': 'v2',
      'eventId': 'e2',
      'promoterId': 'admin-1',
      'isActive': true,
    },
    {
      'id': 'vip3',
      'venueName': 'Clé Houston',
      'packageName': 'Ultimate VIP Package',
      'description': 'The ultimate nightlife experience with all premium perks',
      'price': 399.99,
      'benefits': ['Private VIP section', 'Premium bottle service', 'VIP parking', 'Personal concierge', 'Complimentary valet', 'Exclusive entrance'],
      'imageUrl': 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3',
      'venueType': 'Nightclub',
      'venueId': 'v3',
      'eventId': null,
      'promoterId': 'admin-1',
      'isActive': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredPackages {
    var filtered = List<Map<String, dynamic>>.from(_vipPackages);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((pkg) {
        return pkg['packageName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            pkg['venueName'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedFilter != null) {
      switch (_selectedFilter) {
        case 'active':
          filtered = filtered.where((p) => p['isActive'] == true).toList();
          break;
        case 'inactive':
          filtered = filtered.where((p) => p['isActive'] == false).toList();
          break;
        case 'withEvent':
          filtered = filtered.where((p) => p['eventId'] != null).toList();
          break;
        case 'venueOnly':
          filtered = filtered.where((p) => p['eventId'] == null).toList();
          break;
      }
    }

    return filtered;
  }

  void _deletePackage(String packageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete VIP Package?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _vipPackages.removeWhere((p) => p['id'] == packageId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('VIP Package deleted')),
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

  void _toggleActive(String packageId) {
    setState(() {
      final package = _vipPackages.firstWhere((p) => p['id'] == packageId);
      package['isActive'] = !(package['isActive'] as bool);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _vipPackages.firstWhere((p) => p['id'] == packageId)['isActive']
              ? 'Package activated'
              : 'Package deactivated',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage VIP Packages'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add VIP Package',
            onPressed: () async {
              final newPackage = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminEditVipPackageScreen(),
                ),
              );
              if (newPackage != null) {
                setState(() {
                  _vipPackages.add(newPackage);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('VIP Package created successfully')),
                  );
                }
              }
            },
          ),
        ],
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
                    hintText: 'Search VIP packages...',
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
                        label: const Text('Active'),
                        selected: _selectedFilter == 'active',
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? 'active' : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('With Event'),
                        selected: _selectedFilter == 'withEvent',
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? 'withEvent' : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Venue Only'),
                        selected: _selectedFilter == 'venueOnly',
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? 'venueOnly' : null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // VIP Packages List
          Expanded(
            child: _filteredPackages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 64,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No VIP packages found',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredPackages.length,
                    itemBuilder: (context, index) {
                      final package = _filteredPackages[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.star,
                              color: theme.primaryColor,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  package['packageName'],
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              if (!package['isActive'])
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Inactive',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${package['venueName']} • ${package['venueType']}'),
                              if (package['eventId'] != null)
                                Text(
                                  'For specific event',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                currencyFormat.format(package['price']),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      package['isActive'] ? Icons.pause : Icons.play_arrow,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(package['isActive'] ? 'Deactivate' : 'Activate'),
                                  ],
                                ),
                                onTap: () => _toggleActive(package['id']),
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
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  if (mounted) {
                                    final updatedPackage = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminEditVipPackageScreen(
                                          package: package,
                                        ),
                                      ),
                                    );
                                    if (updatedPackage != null) {
                                      setState(() {
                                        final index = _vipPackages.indexWhere((p) => p['id'] == package['id']);
                                        if (index != -1) {
                                          _vipPackages[index] = updatedPackage;
                                        }
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('VIP Package updated successfully')),
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
                                onTap: () => _deletePackage(package['id']),
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



