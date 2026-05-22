import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/figma_theme.dart';
import '../../utils/wtva_feedback.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'How do I earn points?',
      'Check in at venues, post photos, and stay checked in. Higher ranks unlock paid invites from businesses.',
    ),
    (
      'What is Vibe Master?',
      'At 10,000 points you become Vibe Master. Venues can invite you to paid check-ins.',
    ),
    (
      'How do venue invites work?',
      'Businesses send invites through the app. Accept to check in and earn bonus points.',
    ),
    (
      'Can I use the app without location?',
      'Location helps find nearby venues and verify check-ins. You can browse with limited features if disabled.',
    ),
  ];

  static const _supportEmail = 'support@wherethevibesat.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Help & support', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._faqs.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FaqTile(question: f.$1, answer: f.$2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WtvaColors.dark400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact us',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('mailto:$_supportEmail')),
                  child: const Text(
                    _supportEmail,
                    style: TextStyle(color: WtvaColors.lavender300, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _showContactDialog(context),
                  child: const Text('Send a message'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WtvaColors.dark400,
        title: const Text('Message support'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'How can we help?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              showWtvaSnack(context, 'Message sent — we\'ll reply within 24 hours', icon: Icons.send);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: WtvaColors.dark400,
        collapsedBackgroundColor: WtvaColors.dark400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 13, color: WtvaColors.neutral300, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
