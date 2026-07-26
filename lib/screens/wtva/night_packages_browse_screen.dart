import 'package:flutter/material.dart';
import '../../services/night_packages_repository.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';
import '../../utils/vibe_copy.dart';
import 'night_package_detail_screen.dart';
import 'night_package_orders_screen.dart';
import 'night_package_plan_screen.dart';

class NightPackagesBrowseScreen extends StatefulWidget {
  const NightPackagesBrowseScreen({
    super.key,
    this.embedded = false,
    this.occasionKey,
  });

  final bool embedded;
  final String? occasionKey;

  @override
  State<NightPackagesBrowseScreen> createState() =>
      _NightPackagesBrowseScreenState();
}

class _NightPackagesBrowseScreenState extends State<NightPackagesBrowseScreen> {
  late Future<List<NightPackageRecord>> _future;
  late String? _occasionKey;
  int _hubTab = 0; // 0 Vibes, 1 My Plans

  @override
  void initState() {
    super.initState();
    _occasionKey = widget.occasionKey;
    _future = NightPackagesRepository.instance.listPublished();
  }

  List<NightPackageRecord> _filter(List<NightPackageRecord> all) {
    final key = _occasionKey;
    if (key == null || key.isEmpty) return all;
    return all
        .where(
          (p) => matchesOccasionVibe(
            vibeKey: key,
            templateKey: p.templateKey,
            title: p.title,
            slug: p.slug,
            vibeTags: p.vibeTags,
          ),
        )
        .toList();
  }

  String? get _occasionTitle {
    final key = _occasionKey;
    if (key == null) return null;
    for (final o in occasionVibes) {
      if (o.key == key) return o.title;
    }
    return null;
  }

  Future<void> _openMyPlans() async {
    if (UserService().isGuest) {
      await AccountGate.requireSignIn(context);
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NightPackageOrdersScreen()),
    );
  }

  Future<void> _openDiyPlan({required bool random}) async {
    final repo = NightPackagesRepository.instance;
    final pkg = await repo.getPublished(NightPackagesRepository.diyVibeSlug) ??
        await repo.getPublished(NightPackagesRepository.diyVibeId);
    if (!mounted) return;
    if (pkg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Build Your Own is not available yet. Try again soon.'),
        ),
      );
      return;
    }
    List<ApprovedStopOfferRecord>? seed;
    if (random) {
      seed = await repo.shuffleRandomDiyVibe();
      if (!mounted) return;
      if (seed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No live experiences yet — try Build Your Own.'),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NightPackagePlanScreen(
          package: pkg,
          seedStops: seed ?? const [],
          allowEmptyStart: true,
          showShuffle: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          VibeCopy.curatedTitle,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<NightPackageRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? const [];
          final packages = _filter(all);
          final occasionTitle = _occasionTitle;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = NightPackagesRepository.instance.listPublished();
              });
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                if (occasionTitle != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: WtvaColors.accentPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          occasionTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: WtvaColors.accentPurple,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => setState(() => _occasionKey = null),
                        style: TextButton.styleFrom(
                          foregroundColor: WtvaColors.neutral300,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Clear filter · see all ${all.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  const Text(
                    VibeCopy.curatedSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: WtvaColors.neutral300,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: WtvaColors.dark400,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: WtvaColors.night200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HubTab(
                          label: VibeCopy.vibesTab,
                          selected: _hubTab == 0,
                          onTap: () => setState(() => _hubTab = 0),
                        ),
                      ),
                      Expanded(
                        child: _HubTab(
                          label: VibeCopy.myPlans,
                          selected: _hubTab == 1,
                          onTap: () => setState(() => _hubTab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_hubTab == 1)
                  _MyPlansTeaser(onOpen: _openMyPlans)
                else ...[
                  if (occasionTitle == null) ...[
                    _DiyEntryRow(
                      onSurprise: () => _openDiyPlan(random: true),
                      onBuild: () => _openDiyPlan(random: false),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (packages.isEmpty)
                    _EmptyVibes(
                      occasionTitle: occasionTitle,
                      onBrowseAll: occasionTitle != null
                          ? () => setState(() => _occasionKey = null)
                          : null,
                    )
                  else
                    ...packages.map(
                      (pkg) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PackageImageCard(
                          package: pkg,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NightPackageDetailScreen(
                                packageId: pkg.pathId,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HubTab extends StatelessWidget {
  const _HubTab({
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
                fontSize: 13,
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

class _DiyEntryRow extends StatelessWidget {
  const _DiyEntryRow({
    required this.onSurprise,
    required this.onBuild,
  });

  final VoidCallback onSurprise;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DiyEntryCard(
            title: VibeCopy.surpriseMe,
            subtitle: 'Shuffle a full night from the live pool.',
            onTap: onSurprise,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DiyEntryCard(
            title: VibeCopy.buildYourOwn,
            subtitle: 'Start empty and mix venues yourself.',
            onTap: onBuild,
          ),
        ),
      ],
    );
  }
}

class _DiyEntryCard extends StatelessWidget {
  const _DiyEntryCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WtvaColors.night200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: WtvaColors.neutral50,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: WtvaColors.neutral300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPlansTeaser extends StatelessWidget {
  const _MyPlansTeaser({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WtvaColors.night200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            VibeCopy.myPlans,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: WtvaColors.neutral50,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Confirmation codes and per-stop redemption live here after checkout.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: WtvaColors.neutral300,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onOpen,
            style: TextButton.styleFrom(
              foregroundColor: WtvaColors.accentPurple,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Open my plans →',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVibes extends StatelessWidget {
  const _EmptyVibes({this.occasionTitle, this.onBrowseAll});

  final String? occasionTitle;
  final VoidCallback? onBrowseAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WtvaColors.night200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            occasionTitle != null
                ? 'No curated vibes for $occasionTitle yet. Check back as venues add experiences.'
                : VibeCopy.emptyBrowse,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: WtvaColors.neutral300,
            ),
          ),
          if (onBrowseAll != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onBrowseAll,
              style: TextButton.styleFrom(
                foregroundColor: WtvaColors.accentPurple,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Browse all vibes →',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PackageImageCard extends StatelessWidget {
  const _PackageImageCard({required this.package, required this.onTap});

  final NightPackageRecord package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tags = package.vibeTags.isNotEmpty
        ? package.vibeTags
        : package.stops.map((s) => slotTypeLabel(s.slotType)).toList();

    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: WtvaColors.night200),
            boxShadow: WtvaColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        vibeImageUrl(package.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: WtvaColors.buttonGradient,
                          ),
                        ),
                      ),
                      if (package.isFeatured)
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
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
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    if (package.displayTagline.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        package.displayTagline,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: WtvaColors.neutral300,
                        ),
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags
                            .take(5)
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: WtvaColors.accentPurple
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: WtvaColors.accentPurple,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: WtvaColors.buttonGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                VibeCopy.viewVibe,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 16),
                            ],
                          ),
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
    );
  }
}
