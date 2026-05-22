import 'package:flutter/material.dart';
import 'admin_stripe_keys_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // Mock settings values
  double _venueSubmissionFee = 50.0;
  double _eventSubmissionFee = 25.0;
  bool _autoApproveVenues = false;
  bool _autoApproveEvents = false;
  bool _requirePayment = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Submission Fees Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Submission Fees',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Venue Submission Fee',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _venueSubmissionFee,
                          min: 0,
                          max: 500,
                          divisions: 100,
                          label: '\$${_venueSubmissionFee.toStringAsFixed(0)}',
                          onChanged: (value) {
                            setState(() {
                              _venueSubmissionFee = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${_venueSubmissionFee.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Event Submission Fee',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _eventSubmissionFee,
                          min: 0,
                          max: 200,
                          divisions: 80,
                          label: '\$${_eventSubmissionFee.toStringAsFixed(0)}',
                          onChanged: (value) {
                            setState(() {
                              _eventSubmissionFee = value;
                            });
                          }),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${_eventSubmissionFee.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Save fees to database
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Submission fees updated'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Fees'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Approval Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.approval, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Approval Settings',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Auto-approve Venues'),
                    subtitle: const Text('Venues will be automatically approved upon submission'),
                    value: _autoApproveVenues,
                    onChanged: (value) {
                      setState(() {
                        _autoApproveVenues = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto-approve Events'),
                    subtitle: const Text('Events will be automatically approved upon submission'),
                    value: _autoApproveEvents,
                    onChanged: (value) {
                      setState(() {
                        _autoApproveEvents = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Require Payment'),
                    subtitle: const Text('Payment must be completed before submission is processed'),
                    value: _requirePayment,
                    onChanged: (value) {
                      setState(() {
                        _requirePayment = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // App Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'App Settings',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notification Settings'),
                    subtitle: const Text('Configure push notifications'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to notification settings
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Database Management'),
                    subtitle: const Text('Backup and restore data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to database management
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text('Analytics'),
                    subtitle: const Text('View platform analytics'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to analytics
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.vpn_key),
                    title: const Text('Stripe API Keys'),
                    subtitle: const Text('Configure Stripe API keys for payouts'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminStripeKeysScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

