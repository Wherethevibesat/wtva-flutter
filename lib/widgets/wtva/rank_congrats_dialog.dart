import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import 'wtva_gradient_button.dart';

class RankCongratsDialog extends StatelessWidget {
  final String newRank;
  final String message;

  const RankCongratsDialog({
    super.key,
    required this.newRank,
    this.message = 'You unlocked new perks and paid invite eligibility.',
  });

  static Future<void> show(BuildContext context, {required String newRank}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => RankCongratsDialog(newRank: newRank),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: WtvaColors.dark400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: WtvaColors.rankPurpleGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Congrats!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'New level: $newRank',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: WtvaColors.lavender300),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WtvaColors.neutral300, height: 1.4),
            ),
            const SizedBox(height: 24),
            WtvaGradientButton(
              label: 'Awesome',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
