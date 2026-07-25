import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

const _bynSteps = <({IconData icon, String label})>[
  (icon: Icons.auto_awesome_outlined, label: 'Choose a vibe or start from scratch.'),
  (icon: Icons.celebration_outlined, label: 'Add experiences (venues, events, tables).'),
  (icon: Icons.checklist_rtl_rounded, label: 'Review your plan & total.'),
  (icon: Icons.credit_card_rounded, label: 'Checkout — one payment.'),
  (icon: Icons.check_circle_outline_rounded, label: 'Show up & enjoy.'),
];

const _planVibes = <({IconData icon, String title, Color overlay})>[
  (icon: Icons.favorite_rounded, title: 'Date Night', overlay: Color(0xCC881337)),
  (icon: Icons.groups_rounded, title: 'Girls Night Out', overlay: Color(0xCC3B0764)),
  (icon: Icons.cake_rounded, title: 'Birthday Celebration', overlay: Color(0xCC78350F)),
  (icon: Icons.flight_takeoff_rounded, title: 'Out of Town Weekend', overlay: Color(0xCC0F172A)),
  (icon: Icons.diamond_rounded, title: 'Luxury Experience', overlay: Color(0xCC1E1B4B)),
];

/// Steps card matching the web hero “Build Your Night” widget.
class HomeBuildYourNightCard extends StatelessWidget {
  const HomeBuildYourNightCard({super.key, required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: WtvaColors.night200),
        boxShadow: WtvaColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Build Your Night',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: WtvaColors.neutral50,
            ),
          ),
          const SizedBox(height: 14),
          for (final step in _bynSteps) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: WtvaColors.accentPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(step.icon, size: 16, color: WtvaColors.accentPurple),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        step.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: WtvaColors.neutral50,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: WtvaColors.buttonGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: WtvaColors.buttonShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBuild,
                  borderRadius: BorderRadius.circular(28),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Build My Night',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// “Plan your night. Your way.” vibe cards → packages.
class HomePlanYourNightSection extends StatelessWidget {
  const HomePlanYourNightSection({super.key, required this.onSeeAll, required this.onVibeTap});

  final VoidCallback onSeeAll;
  final ValueChanged<String> onVibeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan your night. Your way.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pick a vibe or let our concierge build it for you.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: WtvaColors.neutral300,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: WtvaColors.accentPurple,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 168,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _planVibes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final vibe = _planVibes[i];
              return _PlanVibeCard(
                title: vibe.title,
                icon: vibe.icon,
                overlay: vibe.overlay,
                onTap: () => onVibeTap(vibe.title),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlanVibeCard extends StatelessWidget {
  const _PlanVibeCard({
    required this.title,
    required this.icon,
    required this.overlay,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color overlay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WtvaColors.night200),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                overlay.withValues(alpha: 0.85),
                WtvaColors.accentPurple.withValues(alpha: 0.55),
                const Color(0xFF4A044E),
              ],
            ),
            boxShadow: WtvaColors.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: WtvaColors.buttonGradient,
                    shape: BoxShape.circle,
                    boxShadow: WtvaColors.buttonShadow,
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Concierge banner aligned with the web homepage.
class HomeConciergeBannerCard extends StatelessWidget {
  const HomeConciergeBannerCard({super.key, required this.onAsk});

  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: WtvaColors.dark400,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: WtvaColors.accentPurple.withValues(alpha: 0.25),
          ),
          boxShadow: WtvaColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: WtvaColors.accentPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: WtvaColors.accentPurple),
                  SizedBox(width: 4),
                  Text(
                    'AI CONCIERGE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: WtvaColors.accentPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Not sure where to start?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WtvaColors.neutral50,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tell us the vibe — music, neighborhood, budget — and we’ll match you with a night that fits.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WtvaColors.neutral300,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WtvaColors.dark500,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WtvaColors.night200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ChatBubble(
                      text: 'I’m in town this weekend — plan something fun.',
                      mine: true,
                    ),
                  ),
                  SizedBox(height: 8),
                  _ChatBubble(
                    text: 'Perfect — I’ve put together a weekend flow for you.',
                    mine: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: WtvaColors.buttonGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: WtvaColors.buttonShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAsk,
                    borderRadius: BorderRadius.circular(28),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Ask Concierge →',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mine ? WtvaColors.dark400 : null,
        gradient: mine ? null : WtvaColors.buttonGradient,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(mine ? 14 : 4),
          bottomRight: Radius.circular(mine ? 4 : 14),
        ),
        border: mine ? Border.all(color: WtvaColors.night200) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: mine ? WtvaColors.neutral50 : Colors.white,
          height: 1.3,
        ),
      ),
    );
  }
}
