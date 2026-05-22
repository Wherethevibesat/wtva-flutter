import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

class WtvaTermsScreen extends StatelessWidget {
  const WtvaTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        title: const Text('Terms & policies'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text(
            'Terms of Service',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: WtvaColors.neutral50),
          ),
          SizedBox(height: 12),
          Text(
            'Where The Vibes At helps you discover nightlife venues, check in, earn points, and connect with the scene in your city. '
            'You must be of legal drinking age in your region to use venue and alcohol-related features.',
            style: TextStyle(fontSize: 14, height: 1.6, color: WtvaColors.neutral200),
          ),
          SizedBox(height: 24),
          Text(
            'Privacy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: WtvaColors.neutral50),
          ),
          SizedBox(height: 12),
          Text(
            'We use location to show nearby venues, store account and check-in data you create, and send notifications you opt into. '
            'You can request account deletion by contacting support.',
            style: TextStyle(fontSize: 14, height: 1.6, color: WtvaColors.neutral200),
          ),
          SizedBox(height: 24),
          Text(
            'Community',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: WtvaColors.neutral50),
          ),
          SizedBox(height: 12),
          Text(
            'Do not post illegal, harassing, or misleading content. Venues and promoters are responsible for offers they publish.',
            style: TextStyle(fontSize: 14, height: 1.6, color: WtvaColors.neutral200),
          ),
        ],
      ),
    );
  }
}
