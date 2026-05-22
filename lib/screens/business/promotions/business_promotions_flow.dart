import 'package:flutter/material.dart';
import '../../../models/business/business_models.dart';
import '../../../services/business_service.dart';
import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';
import '../../../widgets/business/business_widgets.dart';
import '../../../widgets/wtva/wtva_gradient_button.dart';

/// #07 Promotions list, create, review order, featured ad.
class BusinessPromotionsScreen extends StatelessWidget {
  const BusinessPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BusinessService.instance,
      builder: (context, _) {
        final promos = BusinessService.instance.promotions;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            Text('Promotions', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Featured ads and venue promotions.', style: TextStyle(color: WtvaColors.neutral300, fontSize: 14)),
            const SizedBox(height: 20),
            ...promos.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PromoTile(promo: p),
              ),
            ),
            WtvaGradientButton(
              label: 'Create promotion',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessCreatePromotionScreen())),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessFeaturedAdScreen())),
              style: OutlinedButton.styleFrom(
                foregroundColor: WtvaColors.neutral100,
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: WtvaColors.night200),
              ),
              child: const Text('Create featured ad'),
            ),
          ],
        );
      },
    );
  }
}

class _PromoTile extends StatelessWidget {
  final BusinessPromotion promo;

  const _PromoTile({required this.promo});

  @override
  Widget build(BuildContext context) {
    return BusinessCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(promo.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: WtvaColors.night200, borderRadius: BorderRadius.circular(6)),
                child: Text(promo.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(promo.detail, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
        ],
      ),
    );
  }
}

class BusinessCreatePromotionScreen extends StatefulWidget {
  const BusinessCreatePromotionScreen({super.key});

  @override
  State<BusinessCreatePromotionScreen> createState() => _BusinessCreatePromotionScreenState();
}

class _BusinessCreatePromotionScreenState extends State<BusinessCreatePromotionScreen> {
  final _title = TextEditingController(text: 'Friday VIP tables');
  final _desc = TextEditingController(text: '50% off entry before 11 PM. Show app at door.');
  DateTime _ends = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Create promotion', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 16),
          TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ends', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${_ends.month}/${_ends.day}/${_ends.year}', style: const TextStyle(color: WtvaColors.neutral300)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final p = await showDatePicker(
                context: context,
                initialDate: _ends,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (p != null) setState(() => _ends = p);
            },
          ),
          const SizedBox(height: 32),
          WtvaGradientButton(
            label: 'Review order',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BusinessReviewOrderScreen(
                  title: _title.text.trim(),
                  description: _desc.text.trim(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessReviewOrderScreen extends StatelessWidget {
  final String title;
  final String description;

  const BusinessReviewOrderScreen({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Review order', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          BusinessCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: WtvaColors.neutral200)),
                const Divider(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Promotion fee'),
                    Text('\$29', style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          WtvaGradientButton(
            label: 'Publish promotion',
            onPressed: () async {
              await BusinessService.instance.addPromotion(
                BusinessPromotion(
                  id: 'p-${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  status: 'Live',
                  detail: 'Just published',
                  description: description,
                ),
              );
              if (!context.mounted) return;
              Navigator.popUntil(context, (r) => r.isFirst);
              showWtvaSnack(context, 'Promotion published', icon: Icons.campaign);
            },
          ),
        ],
      ),
    );
  }
}

class BusinessFeaturedAdScreen extends StatelessWidget {
  const BusinessFeaturedAdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Featured ad', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Boost visibility on Discover with a featured placement.',
              style: TextStyle(color: WtvaColors.neutral300),
            ),
            const SizedBox(height: 20),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: WtvaColors.dark400,
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1571266028245-e68f8574baca?w=800&q=80'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Spacer(),
            WtvaGradientButton(
              label: 'Purchase featured slot (\$99 demo)',
              onPressed: () {
                Navigator.pop(context);
                showWtvaSnack(context, 'Featured ad scheduled (demo)', icon: Icons.star);
              },
            ),
          ],
        ),
      ),
    );
  }
}
