import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import '../../utils/vibe_copy.dart';
import 'night_package_orders_screen.dart';

class NightPackageSuccessScreen extends StatelessWidget {
  const NightPackageSuccessScreen({
    super.key,
    required this.packageName,
    required this.amount,
    required this.partySize,
    required this.stopCount,
    this.startsOnLabel,
  });

  final String packageName;
  final double amount;
  final int partySize;
  final int stopCount;
  final String? startsOnLabel;

  @override
  Widget build(BuildContext context) {
    final money =
        '\$${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
    final when = startsOnLabel != null ? ' for $startsOnLabel' : '';

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        title: const Text('Booked'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: WtvaColors.accentGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              VibeCopy.bookedTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: WtvaColors.neutral50,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "You're done",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: WtvaColors.neutral200,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$packageName is booked$when. Open your plan for per-stop codes. · $stopCount experiences · $partySize guests · $money',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: WtvaColors.neutral300,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const NightPackageOrdersScreen(),
                    ),
                    (route) => route.isFirst,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: WtvaColors.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'View My Plans',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Back to vibe'),
            ),
          ],
        ),
      ),
    );
  }
}
