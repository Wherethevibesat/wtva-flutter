import 'package:flutter/material.dart';
import '../../services/stripe_service.dart';

class AdminStripeKeysScreen extends StatefulWidget {
  const AdminStripeKeysScreen({super.key});

  @override
  State<AdminStripeKeysScreen> createState() => _AdminStripeKeysScreenState();
}

class _AdminStripeKeysScreenState extends State<AdminStripeKeysScreen> {
  final _formKey = GlobalKey<FormState>();
  final _publishableKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  bool _obscureSecretKey = true;
  bool _isLoading = false;
  bool _isSaving = false;
  final StripeService _stripeService = StripeService();

  @override
  void initState() {
    super.initState();
    _loadStripeKeys();
  }

  @override
  void dispose() {
    _publishableKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadStripeKeys() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final keys = await _stripeService.getStripeKeys();
      if (keys != null) {
        _publishableKeyController.text = keys['publishable_key'] ?? '';
        _secretKeyController.text = keys['secret_key'] ?? '';
      }
    } catch (e) {
      // Keys not found, that's okay
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveStripeKeys() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _stripeService.saveStripeKeys(
        publishableKey: _publishableKeyController.text.trim(),
        secretKey: _secretKeyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stripe keys saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving keys: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final isValid = await _stripeService.testStripeConnection(
        publishableKey: _publishableKeyController.text.trim(),
        secretKey: _secretKeyController.text.trim(),
      );

      if (mounted) {
        if (isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stripe connection successful!'),
              backgroundColor: Colors.green,
            ),
          );
          // Auto-save if connection is valid
          await _saveStripeKeys();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stripe connection failed. Please check your keys.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing connection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe API Keys'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info Card
                Card(
                  color: theme.primaryColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: theme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Stripe API Keys',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter your Stripe API keys to enable payouts. You can find these in your Stripe Dashboard under Settings → API keys.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Keep your secret key secure. Never share it publicly.',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API Keys',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),

                          // Publishable Key
                          TextFormField(
                            controller: _publishableKeyController,
                            decoration: InputDecoration(
                              labelText: 'Publishable Key',
                              hintText: 'pk_test_... or pk_live_...',
                              prefixIcon: const Icon(Icons.vpn_key),
                              border: const OutlineInputBorder(),
                              helperText: 'Starts with pk_test_ or pk_live_',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your publishable key';
                              }
                              if (!value.startsWith('pk_')) {
                                return 'Publishable key must start with pk_';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Secret Key
                          TextFormField(
                            controller: _secretKeyController,
                            decoration: InputDecoration(
                              labelText: 'Secret Key',
                              hintText: 'sk_test_... or sk_live_...',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureSecretKey
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureSecretKey = !_obscureSecretKey;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                              helperText: 'Starts with sk_test_ or sk_live_',
                            ),
                            obscureText: _obscureSecretKey,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your secret key';
                              }
                              if (!value.startsWith('sk_')) {
                                return 'Secret key must start with sk_';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isSaving ? null : _testConnection,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.check_circle),
                                  label: const Text('Test & Save'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _saveStripeKeys,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: const Text('Save Keys'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Help Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How to Get Your Stripe API Keys',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _HelpStep(
                          number: '1',
                          text: 'Go to https://dashboard.stripe.com',
                        ),
                        _HelpStep(
                          number: '2',
                          text: 'Navigate to Settings → API keys',
                        ),
                        _HelpStep(
                          number: '3',
                          text: 'Copy your Publishable key (starts with pk_)',
                        ),
                        _HelpStep(
                          number: '4',
                          text: 'Click "Reveal test key" or "Reveal live key" to see your Secret key (starts with sk_)',
                        ),
                        _HelpStep(
                          number: '5',
                          text: 'Paste both keys above and click "Test & Save"',
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

class _HelpStep extends StatelessWidget {
  final String number;
  final String text;

  const _HelpStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

