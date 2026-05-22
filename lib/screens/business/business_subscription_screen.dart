import 'package:flutter/material.dart';
import '../../data/mock_business_data.dart';
import '../../models/business/business_models.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_auth_shell.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';

/// #02_19 Choose plan — Silver / Gold / Platinum.
class BusinessSubscriptionScreen extends StatelessWidget {
  final BusinessSubscriptionTier selected;
  final ValueChanged<BusinessSubscriptionTier> onSelect;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const BusinessSubscriptionScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return WtvaAuthShell(
      showBack: true,
      onBack: onBack,
      onClose: () => Navigator.maybePop(context),
      bottomButtonLabel: 'Continue with plan',
      bottomEnabled: true,
      onBottomPressed: onContinue,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          const Text('Choose plan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Unlock browse users, bookings, and promotions. Billing is saved to your account — payment collection can be added later.',
            style: TextStyle(color: WtvaColors.neutral300, height: 1.35),
          ),
          const SizedBox(height: 24),
          ...BusinessSubscriptionTier.values.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                tier: t,
                selected: selected == t,
                perks: MockBusinessData.subscriptionPerks[t] ?? [],
                onTap: () => onSelect(t),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final BusinessSubscriptionTier tier;
  final bool selected;
  final List<String> perks;
  final VoidCallback onTap;

  const _PlanCard({
    required this.tier,
    required this.selected,
    required this.perks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? WtvaColors.neutral50 : WtvaColors.night200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(tier.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(tier.priceLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              ...perks.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 16, color: WtvaColors.neutral200),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p, style: const TextStyle(fontSize: 13, color: WtvaColors.neutral200))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BusinessApplePayDemoScreen extends StatelessWidget {
  final VoidCallback onDone;

  const BusinessApplePayDemoScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Subscribe & pay', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.apple, size: 64, color: WtvaColors.neutral50),
            const SizedBox(height: 16),
            const Text(
              'Apple Pay · demo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Subscription activates immediately in demo mode.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WtvaColors.neutral300),
            ),
            const Spacer(),
            WtvaGradientButton(
              label: 'Confirm payment',
              onPressed: () {
                Navigator.pop(context);
                onDone();
              },
            ),
          ],
        ),
      ),
    );
  }
}
