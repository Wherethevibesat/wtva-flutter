import 'package:flutter/material.dart';
import '../../services/night_packages_repository.dart';
import '../../theme/figma_theme.dart';
import '../../utils/vibe_copy.dart';

/// Quick-start chips shown on the Build My Vibe hero card.
const _buildVibeChips = <({String? occasionKey, String label, IconData icon})>[
  (occasionKey: 'date_night', label: 'Date Night', icon: Icons.favorite_rounded),
  (occasionKey: 'girls_night', label: 'Girls Night', icon: Icons.groups_rounded),
  (occasionKey: 'birthday', label: 'Birthday', icon: Icons.cake_rounded),
  (occasionKey: null, label: VibeCopy.surpriseMe, icon: Icons.casino_rounded),
];

/// Compact shared height for Pick your vibe / Curated Vibes carousels.
const kHomeVibeCardHeight = 156.0;

/// Hero card — occasion chips + Surprise Me + Build From Scratch.
class HomeBuildYourNightCard extends StatelessWidget {
  const HomeBuildYourNightCard({
    super.key,
    required this.onOccasionTap,
    required this.onSurpriseMe,
    required this.onBuildFromScratch,
  });

  final ValueChanged<String> onOccasionTap;
  final VoidCallback onSurpriseMe;
  final VoidCallback onBuildFromScratch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F4FF),
            Color(0xFFFFF5FB),
            Color(0xFFFFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9D5FF).withValues(alpha: 0.7)),
        boxShadow: WtvaColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      VibeCopy.buildMyVibe,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral50,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan the perfect vibe from start to finish.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: WtvaColors.neutral300,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = 6.0;
                        final chipW =
                            ((constraints.maxWidth - gap * 3) / 4)
                                .clamp(52.0, 72.0);
                        return Row(
                          children: [
                            for (var i = 0; i < _buildVibeChips.length; i++) ...[
                              if (i > 0) SizedBox(width: gap),
                              SizedBox(
                                width: chipW,
                                child: _BuildVibeChip(
                                  label: _buildVibeChips[i].label,
                                  icon: _buildVibeChips[i].icon,
                                  onTap: () {
                                    final key = _buildVibeChips[i].occasionKey;
                                    if (key == null) {
                                      onSurpriseMe();
                                    } else {
                                      onOccasionTap(key);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Image.asset(
                'assets/images/build_vibe_crystal.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  onTap: onBuildFromScratch,
                  borderRadius: BorderRadius.circular(28),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${VibeCopy.buildFromScratch} →',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
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

class _BuildVibeChip extends StatelessWidget {
  const _BuildVibeChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WtvaColors.night200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    WtvaColors.buttonGradient.createShader(bounds),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: WtvaColors.neutral200,
                ),
              ),
            ],
          ),
        ),
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
                height: kHomeVibeCardHeight,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: occasionVibes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
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
                height: kHomeVibeCardHeight,
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
              height: kHomeVibeCardHeight,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: show.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 120,
          height: kHomeVibeCardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WtvaColors.night200),
            boxShadow: WtvaColors.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: WtvaColors.buttonGradient,
                          shape: BoxShape.circle,
                          boxShadow: WtvaColors.buttonShadow,
                        ),
                        child: Icon(vibe.icon, color: Colors.white, size: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vibe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          height: 1.2,
                          shadows: [
                            Shadow(blurRadius: 6, color: Colors.black54),
                          ],
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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 160,
          height: kHomeVibeCardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WtvaColors.night200),
            boxShadow: WtvaColors.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: WtvaColors.buttonGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        VibeCopy.featuredBadge,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        package.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.2,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black54),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '${VibeCopy.viewVibe} →',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
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
