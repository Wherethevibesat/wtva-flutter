import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminPendingSubmissionsScreen extends StatefulWidget {
  const AdminPendingSubmissionsScreen({super.key});

  @override
  State<AdminPendingSubmissionsScreen> createState() => _AdminPendingSubmissionsScreenState();
}

class _AdminPendingSubmissionsScreenState extends State<AdminPendingSubmissionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock pending submissions
  final List<Map<String, dynamic>> _pendingVenues = [
    {
      'id': 'v1',
      'name': 'The New Club',
      'type': 'Nightclub',
      'neighborhood': 'Downtown',
      'submittedBy': 'John Doe',
      'submittedAt': DateTime.now().subtract(const Duration(days: 2)),
      'address': '123 Main St, Houston, TX',
    },
    {
      'id': 'v2',
      'name': 'Rooftop Lounge',
      'type': 'Rooftop',
      'neighborhood': 'Midtown',
      'submittedBy': 'Jane Smith',
      'submittedAt': DateTime.now().subtract(const Duration(days: 1)),
      'address': '456 Oak Ave, Houston, TX',
    },
  ];

  final List<Map<String, dynamic>> _pendingEvents = [
    {
      'id': 'e1',
      'title': 'Friday Night Party',
      'venueName': 'The New Club',
      'eventType': 'Party',
      'neighborhood': 'Downtown',
      'date': DateTime.now().add(const Duration(days: 5)),
      'submittedBy': 'John Doe',
      'submittedAt': DateTime.now().subtract(const Duration(hours: 12)),
    },
    {
      'id': 'e2',
      'title': 'Live DJ Set',
      'venueName': 'Rooftop Lounge',
      'eventType': 'DJ Set',
      'neighborhood': 'Midtown',
      'date': DateTime.now().add(const Duration(days: 7)),
      'submittedBy': 'Jane Smith',
      'submittedAt': DateTime.now().subtract(const Duration(hours: 6)),
    },
  ];

  void _approveSubmission(String type, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve $type?'),
        content: Text('This ${type.toLowerCase()} will be published and visible to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement approval logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$type approved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {
                if (type == 'Venue') {
                  _pendingVenues.removeWhere((v) => v['id'] == id);
                } else {
                  _pendingEvents.removeWhere((e) => e['id'] == id);
                }
              });
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectSubmission(String type, String id) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $type?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement rejection logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$type rejected'),
                  backgroundColor: Colors.orange,
                ),
              );
              setState(() {
                if (type == 'Venue') {
                  _pendingVenues.removeWhere((v) => v['id'] == id);
                } else {
                  _pendingEvents.removeWhere((e) => e['id'] == id);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
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
        title: const Text('Pending Submissions'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Venues'),
                  if (_pendingVenues.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingVenues.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Events'),
                  if (_pendingEvents.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingEvents.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Venues Tab
          _pendingVenues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending venues',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All venue submissions have been reviewed',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingVenues.length,
                  itemBuilder: (context, index) {
                    final venue = _pendingVenues[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        venue['name'],
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${venue['type']} • ${venue['neighborhood']}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              context,
                              Icons.location_on,
                              venue['address'],
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              context,
                              Icons.person,
                              'Submitted by ${venue['submittedBy']}',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              context,
                              Icons.access_time,
                              '${DateFormat('MMM d, y').format(venue['submittedAt'])} at ${DateFormat('h:mm a').format(venue['submittedAt'])}',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _rejectSubmission('Venue', venue['id']),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approveSubmission('Venue', venue['id']),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

          // Events Tab
          _pendingEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending events',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All event submissions have been reviewed',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingEvents.length,
                  itemBuilder: (context, index) {
                    final event = _pendingEvents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['title'],
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${event['eventType']} • ${event['venueName']}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              context,
                              Icons.location_city,
                              event['neighborhood'],
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              context,
                              Icons.calendar_today,
                              DateFormat('MMM d, y • h:mm a').format(event['date']),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              context,
                              Icons.person,
                              'Submitted by ${event['submittedBy']}',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _rejectSubmission('Event', event['id']),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approveSubmission('Event', event['id']),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

