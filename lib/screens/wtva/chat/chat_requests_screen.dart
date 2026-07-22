import 'package:flutter/material.dart';
import '../../../data/mock_social_data.dart';
import '../../../theme/figma_theme.dart';

class ChatRequestsScreen extends StatelessWidget {
  const ChatRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = MockSocialData.requests;
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Requests', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: requests.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No message requests',
                  style: TextStyle(color: WtvaColors.neutral300),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = requests[i];
                return Material(
                  color: WtvaColors.dark400,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: WtvaColors.dark300,
                      child: Icon(r.isBusiness ? Icons.storefront : Icons.person),
                    ),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      r.preview,
                      style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
