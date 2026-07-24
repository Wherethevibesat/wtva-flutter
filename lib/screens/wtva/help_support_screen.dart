import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/figma_theme.dart';
import '../../utils/wtva_feedback.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'How do I check in?',
      'Open the center scan button, pick a venue nearby (or scan the venue QR if required), and confirm. Location helps verify you’re on site.',
    ),
    (
      'What is Vibes Concierge?',
      'Ask for nightlife picks by vibe, neighborhood, or timing. Concierge recommends real events and venues from WTVA.',
    ),
    (
      'How do venue invites work?',
      'Businesses can send invites through the app. Accept to check in when you arrive.',
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
              border: Border.all(color: WtvaColors.night200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Email our team and we’ll get back to you.',
                  style: TextStyle(color: WtvaColors.neutral300, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    final uri = Uri(
                      scheme: 'mailto',
                      path: _supportEmail,
                      query: 'subject=WTVA Support',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else if (context.mounted) {
                      showWtvaSnack(context, _supportEmail, icon: Icons.email_outlined);
                    }
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text(_supportEmail),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w700)),
        children: [
          Text(answer, style: const TextStyle(color: WtvaColors.neutral300, height: 1.4)),
        ],
      ),
    );
  }
}
