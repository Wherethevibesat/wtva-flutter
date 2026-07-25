import 'package:flutter/material.dart';
import '../../services/night_packages_repository.dart';
import '../../theme/figma_theme.dart';
import '../../utils/vibe_copy.dart';

const _bynSteps = <({IconData icon, String label})>[
  (
    icon: Icons.auto_awesome_outlined,
    label: 'Choose a curated vibe or start from scratch.',
  ),
  (
    icon: Icons.celebration_outlined,
    label: 'Add experiences (places, events, tables).',
  ),
  (
    icon: Icons.checklist_rtl_rounded,
    label: 'Review your plan & total.',
  ),
  (
    icon: Icons.credit_card_rounded,
    label: 'Checkout — one payment.',
  ),
  (
    icon: Icons.check_circle_outline_rounded,
    label: 'Show up & enjoy.',
  ),
];

/// Steps card matching the web hero “Build My Vibe” widget.
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
            VibeCopy.buildMyVibe,
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
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: WtvaColors.accentPurple.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      step.icon,
                      size: 18,
                      color: WtvaColors.accentPurple,
                    ),
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
                          VibeCopy.buildMyVibe,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
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

/// Pick your vibe / Curated Vibes tabs (matches web `home-vibe-tabs`).
class HomePlanYourNightSection extends StatefulWidget {
  const HomePlanYourNightSection({
    super.key,
    required this.onSeeAll,
    required this.onOccasionTap,
    required this.onPackageTap,
  });

  final VoidCallback onSeeAll;
  /// Occasion key + optional matching package pathId for deep-link.
  final void Function(String occasionKey, NightPackageRecord? match) onOccasionTap;
  final ValueChanged<NightPackageRecord> onPackageTap;

  @override
  State<HomePlanYourNightSection> createState() =>
      _HomePlanYourNightSectionState();
}

class _HomePlanYourNightSectionState extends State<HomePlanYourNightSection> {
  int _tab = 0; // 0 pick, 1 curated
  late Future<List<NightPackageRecord>> _packages;

  @override
  void initState() {
    super.initState();
    _packages = NightPackagesRepository.instance.listPublished(limit: 40);
  }

  NightPackageRecord? _matchOccasion(
    List<NightPackageRecord> packages,
    String key,
  ) {
    for (final p in packages) {
      if (matchesOccasionVibe(
        vibeKey: key,
        templateKey: p.templateKey,
        title: p.title,
        slug: p.slug,
        vibeTags: p.vibeTags,
      )) {
        return p;
      }
    }
    return null;
  }

  List<NightPackageRecord> _curatedShow(List<NightPackageRecord> packages) {
    final featured = packages.where((p) => p.isFeatured).toList();
    final source = featured.isNotEmpty ? featured : packages;
    return source.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = _tab == 0 ? VibeCopy.pickYourVibe : VibeCopy.curatedTitle;
    final subtitle = _tab == 0
        ? VibeCopy.pickYourVibeSubtitle
        : 'Designed by our concierge — brunch to late night, and everything between.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: WtvaColors.neutral300,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: widget.onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: WtvaColors.accentPurple,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '${VibeCopy.seeAllVibes} →',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: WtvaColors.dark400,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: WtvaColors.night200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _VibeTabChip(
                    label: VibeCopy.pickYourVibe,
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                ),
                Expanded(
                  child: _VibeTabChip(
                    label: VibeCopy.curatedTitle,
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<NightPackageRecord>>(
          future: _packages,
          builder: (context, snapshot) {
            final packages = snapshot.data ?? const [];
            if (_tab == 0) {
              return SizedBox(
                height: 200,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: occasionVibes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final vibe = occasionVibes[i];
                    final match = _matchOccasion(packages, vibe.key);
                    return _OccasionPhotoCard(
                      vibe: vibe,
                      onTap: () => widget.onOccasionTap(vibe.key, match),
                    );
                  },
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final show = _curatedShow(packages);
            if (show.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  VibeCopy.emptyBrowse,
                  style: TextStyle(color: WtvaColors.neutral300, fontSize: 13),
                ),
              );
            }

            return SizedBox(
              height: 280,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: show.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final pkg = show[i];
                  return _CuratedPhotoCard(
                    package: pkg,
                    onTap: () => widget.onPackageTap(pkg),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VibeTabChip extends StatelessWidget {
  const _VibeTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected ? WtvaColors.buttonGradient : null,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : WtvaColors.neutral300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OccasionPhotoCard extends StatelessWidget {
  const _OccasionPhotoCard({required this.vibe, required this.onTap});

  final OccasionVibe vibe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WtvaColors.night200),
            boxShadow: WtvaColors.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  vibePlaceholderImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: WtvaColors.dark500),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [vibe.overlayTop, vibe.overlayBottom],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: WtvaColors.buttonGradient,
                          shape: BoxShape.circle,
                          boxShadow: WtvaColors.buttonShadow,
                        ),
                        child: Icon(vibe.icon, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vibe.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            height: 1.2,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black54),
                            ],
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
      ),
    );
  }
}

class _CuratedPhotoCard extends StatelessWidget {
  const _CuratedPhotoCard({required this.package, required this.onTap});

  final NightPackageRecord package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WtvaColors.night200),
            boxShadow: WtvaColors.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  vibeImageUrl(package.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: WtvaColors.dark500),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x40000000),
                        Color(0xCC000000),
                      ],
                    ),
                  ),
                ),
                if (package.isFeatured)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: WtvaColors.buttonGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        VibeCopy.featuredBadge,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black54),
                          ],
                        ),
                      ),
                      if (package.displayTagline.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          package.displayTagline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Text(
                        '${VibeCopy.viewVibe} →',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
