import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_edit_event_screen.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  String _searchQuery = '';
  String? _selectedFilter;

  // Mock events data
  final List<Map<String, dynamic>> _events = [
    {
      'id': 'e1',
      'title': 'Friday Night Vibes',
      'venueName': 'The Post Oak',
      'eventType': 'Party',
      'neighborhood': 'Galleria/Uptown',
      'date': DateTime.now().add(const Duration(days: 2)),
      'isFeatured': true,
      'status': 'active',
    },
    {
      'id': 'e2',
      'title': 'Weekend Rooftop Party',
      'venueName': 'Z on 23',
      'eventType': 'Party',
      'neighborhood': 'Downtown',
      'date': DateTime.now().add(const Duration(days: 3)),
      'isFeatured': false,
      'status': 'active',
    },
    {
      'id': 'e3',
      'title': 'Saturday Night Live DJ Set',
      'venueName': 'Clé Houston',
      'eventType': 'DJ Set',
      'neighborhood': 'Midtown',
      'date': DateTime.now().add(const Duration(days: 4)),
      'isFeatured': true,
      'status': 'active',
    },
  ];

  List<Map<String, dynamic>> get _filteredEvents {
    var filtered = List<Map<String, dynamic>>.from(_events);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        return event['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            event['venueName'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedFilter != null) {
      switch (_selectedFilter) {
        case 'featured':
          filtered = filtered.where((e) => e['isFeatured'] == true).toList();
          break;
        case 'active':
          filtered = filtered.where((e) => e['status'] == 'active').toList();
          break;
        case 'upcoming':
          filtered = filtered.where((e) => (e['date'] as DateTime).isAfter(DateTime.now())).toList();
          break;
      }
    }

    return filtered;
  }

  void _toggleFeatured(String eventId) {
    setState(() {
      final event = _events.firstWhere((e) => e['id'] == eventId);
      event['isFeatured'] = !(event['isFeatured'] as bool);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _events.firstWhere((e) => e['id'] == eventId)['isFeatured']
              ? 'Event featured'
              : 'Event unfeatured',
        ),
      ),
    );
  }

  void _deleteEvent(String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _events.removeWhere((e) => e['id'] == eventId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event deleted')),
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
        title: const Text('Manage Events'),
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
                    hintText: 'Search events...',
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
                        label: const Text('Upcoming'),
                        selected: _selectedFilter == 'upcoming',
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = selected ? 'upcoming' : null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Events List
          Expanded(
            child: _filteredEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 64,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events found',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = _filteredEvents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.event,
                              color: theme.primaryColor,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event['title'],
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              if (event['isFeatured'])
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
                              Text('${event['eventType']} • ${event['venueName']}'),
                              Text('${event['neighborhood']} • ${DateFormat('MMM d, y • h:mm a').format(event['date'])}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      event['isFeatured'] ? Icons.star_border : Icons.star,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(event['isFeatured'] ? 'Unfeature' : 'Feature'),
                                  ],
                                ),
                                onTap: () => _toggleFeatured(event['id']),
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
                                    final updatedEvent = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminEditEventScreen(
                                          event: event,
                                        ),
                                      ),
                                    );
                                    if (updatedEvent != null) {
                                      setState(() {
                                        final index = _events.indexWhere((e) => e['id'] == event['id']);
                                        if (index != -1) {
                                          _events[index] = updatedEvent;
                                        }
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Event updated successfully')),
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
                                onTap: () => _deleteEvent(event['id']),
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

