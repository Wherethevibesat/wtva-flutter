import 'package:flutter/material.dart';
import '../../data/mock_venue_store.dart';
import '../../models/venue_detail.dart';
import '../../theme/figma_theme.dart';
import 'check_in_options_sheet.dart';
import '../../services/favorites_service.dart';
import '../../utils/account_gate.dart';
import '../../utils/wtva_feedback.dart';
import '../../utils/wtva_links.dart';
import 'venue/venue_media_screens.dart';

class VenueDetailScreen extends StatefulWidget {
  final String venueId;

  const VenueDetailScreen({super.key, required this.venueId});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  bool _favorited = false;
  int _heroPage = 0;
  final _heroController = PageController();

  @override
  void initState() {
    super.initState();
    _favorited = FavoritesService.instance.isFavorite(widget.venueId);
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (!await AccountGate.requireSignIn(
      context,
      message: 'Log in or sign up to save favorite venues.',
    )) {
      return;
    }
    final on = await FavoritesService.instance.toggle(widget.venueId);
    if (!mounted) return;
    setState(() => _favorited = on);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(on ? 'Added to favorites' : 'Removed from favorites'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openCheckIn(VenueDetail detail) async {
    if (!await AccountGate.requireSignIn(context)) return;
    if (!mounted) return;
    await CheckInOptionsSheet.show(
      context,
      venueId: detail.venue.id,
      venueName: detail.venue.name,
    );
  }

  List<String> _heroImages(VenueDetail detail) {
    final base = detail.venue.imageUrl;
    final extras = detail.recentCheckIns.map((p) => p.imageUrl).take(4).toList();
    return [base, ...extras.where((u) => u != base)];
  }

  @override
  Widget build(BuildContext context) {
    final detail = MockVenueStore.byId(widget.venueId);
    if (detail == null) {
      return Scaffold(
        backgroundColor: WtvaColors.dark500,
        appBar: AppBar(
          backgroundColor: WtvaColors.dark500,
          title: const Text('Venue'),
        ),
        body: const Center(child: Text('Venue not found')),
      );
    }
    final v = detail.venue;
    final images = _heroImages(detail);
    final topInset = MediaQuery.paddingOf(context).top;
    final neighborhood = detail.neighborhood;
    final showSocialProof =
        detail.checkInCount > 0 || detail.recentCheckIns.isNotEmpty;

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320 + topInset,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _heroController,
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _heroPage = i),
                        itemBuilder: (_, i) => Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: WtvaColors.dark300),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                            stops: const [0, 0.4, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: topInset + 8,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            _HeroCircleBtn(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            _HeroCircleBtn(
                              icon: Icons.ios_share_rounded,
                              onTap: () => showWtvaSnack(
                                context,
                                'Share link copied for ${v.name}',
                                icon: Icons.ios_share_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _HeroCircleBtn(
                              icon: _favorited
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              iconColor: _favorited
                                  ? WtvaColors.accentPink
                                  : WtvaColors.neutral50,
                              onTap: _toggleFavorite,
                            ),
                          ],
                        ),
                      ),
                      if (showSocialProof)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 28,
                          child: Row(
                            children: [
                              Flexible(
                                child: _SocialProofPill(
                                  count: detail.checkInCount > 0
                                      ? detail.checkInCount
                                      : detail.recentCheckIns.length,
                                  avatars: detail.recentCheckIns
                                      .map((p) => p.avatarUrl)
                                      .take(3)
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length.clamp(1, 5), (i) {
                            final active = i == _heroPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: active
                                    ? WtvaColors.accentPurple
                                    : Colors.white.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: WtvaColors.dark500,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                v.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: WtvaColors.neutral50,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified_rounded,
                              size: 22,
                              color: WtvaColors.accentPurple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            detail.category,
                            if (neighborhood != null && neighborhood.isNotEmpty) neighborhood,
                          ].join(' • '),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: WtvaColors.neutral300,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 14,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (v.rating > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...List.generate(5, (i) {
                                    final filled = i < v.fullStars;
                                    final half = !filled && i == v.fullStars && v.halfStar;
                                    return Icon(
                                      half
                                          ? Icons.star_half_rounded
                                          : filled
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                      size: 16,
                                      color: WtvaColors.accentPurple,
                                    );
                                  }),
                                  const SizedBox(width: 6),
                                  Text(
                                    v.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: WtvaColors.neutral50,
                                    ),
                                  ),
                                ],
                              ),
                            if (v.distanceMiles > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: WtvaColors.neutral300,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${v.distanceMiles.toStringAsFixed(1)} mi away',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: WtvaColors.neutral200,
                                    ),
                                  ),
                                ],
                              ),
                            if (detail.checkInCount > 0)
                              Text(
                                '${detail.checkInCount} check-ins',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: WtvaColors.neutral200,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _QuickInfoGrid(detail: detail),
                        if (detail.recentCheckIns.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _SectionHeader(
                            title: 'Recent vibes',
                            onViewAll: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    VenueAllCheckInsScreen(venueId: widget.venueId),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...detail.recentCheckIns.take(2).map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CheckInCard(
                                    post: p,
                                    onPhotoTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VenuePhotoViewerScreen(
                                          imageUrl: p.imageUrl,
                                          caption: p.caption,
                                          userName: p.userName,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          detail.description,
                          style: const TextStyle(
                            color: WtvaColors.neutral200,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: WtvaColors.neutral300,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                detail.address,
                                style: const TextStyle(
                                  color: WtvaColors.neutral300,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 18,
            bottom: 108,
            child: _CheckInFab(onTap: () => _openCheckIn(detail)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            border: const Border(top: BorderSide(color: WtvaColors.night200)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101115).withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _BottomOutlineBtn(
                  icon: Icons.directions_rounded,
                  label: 'Directions',
                  onPressed: () async {
                    final ok = await openMapsSearch(detail.address);
                    if (!context.mounted) return;
                    if (!ok) showWtvaSnack(context, 'Could not open maps');
                  },
                ),
              ),
              if (detail.phone != null && detail.phone!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _BottomOutlineBtn(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    onPressed: () async {
                      final ok = await openPhoneCall(detail.phone!);
                      if (!context.mounted) return;
                      if (!ok) showWtvaSnack(context, 'Could not start call');
                    },
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: WtvaColors.buttonGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: WtvaColors.buttonShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: () => _openCheckIn(detail),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Check In',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: WtvaColors.onPrimary,
                        ),
                      ),
                    ),
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

class _HeroCircleBtn extends StatelessWidget {
  const _HeroCircleBtn({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor == Colors.white ? WtvaColors.onPrimary : iconColor,
          size: 20,
        ),
      ),
    );
  }
}

class _SocialProofPill extends StatelessWidget {
  const _SocialProofPill({required this.count, required this.avatars});

  final int count;
  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: avatars.isEmpty ? 0 : 18.0 + (avatars.length.clamp(0, 3) - 1) * 14,
            height: 24,
            child: Stack(
              children: [
                for (var i = 0; i < avatars.length.clamp(0, 3); i++)
                  Positioned(
                    left: i * 14.0,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: WtvaColors.dark300,
                      backgroundImage: NetworkImage(avatars[i]),
                    ),
                  ),
              ],
            ),
          ),
          if (avatars.isNotEmpty) const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$count check-ins',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoGrid extends StatelessWidget {
  const _QuickInfoGrid({required this.detail});

  final VenueDetail detail;

  @override
  Widget build(BuildContext context) {
    final hours = detail.hoursLabel.trim().isNotEmpty
        ? detail.hoursLabel
        : (detail.isOpen ? 'Open now' : 'Hours TBA');
    final items = <(IconData, String, String)>[
      (
        Icons.schedule_rounded,
        detail.isOpen ? 'Open' : 'Closed',
        hours,
      ),
      if (detail.checkInCount > 0)
        (
          Icons.groups_rounded,
          '${detail.checkInCount}',
          'check-ins',
        ),
      if (detail.neighborhood != null && detail.neighborhood!.trim().isNotEmpty)
        (
          Icons.place_outlined,
          detail.neighborhood!,
          'Neighborhood',
        ),
      if (detail.category.trim().isNotEmpty)
        (
          Icons.storefront_outlined,
          detail.category,
          'Type',
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WtvaColors.night200),
        boxShadow: WtvaColors.cardShadow,
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 46, color: WtvaColors.night200),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Icon(items[i].$1, size: 18, color: WtvaColors.accentPurple),
                    const SizedBox(height: 6),
                    Text(
                      items[i].$2,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].$3,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: i == 0
                            ? WtvaColors.accentPurple
                            : WtvaColors.neutral300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: WtvaColors.neutral50,
            ),
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: WtvaColors.accentPurple,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'View all',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CheckInFab extends StatelessWidget {
  final VoidCallback onTap;

  const _CheckInFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: WtvaColors.fabGradient,
              shape: BoxShape.circle,
              boxShadow: WtvaColors.buttonShadow,
            ),
            child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check In',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: WtvaColors.neutral200,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomOutlineBtn extends StatelessWidget {
  const _BottomOutlineBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: WtvaColors.neutral50,
          side: const BorderSide(color: WtvaColors.night200),
          backgroundColor: WtvaColors.dark400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final VenueCheckInPost post;
  final VoidCallback? onPhotoTap;

  const _CheckInCard({required this.post, this.onPhotoTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WtvaColors.night200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(post.avatarUrl)),
            title: Text(post.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(post.timeAgo, style: const TextStyle(fontSize: 12)),
          ),
          GestureDetector(
            onTap: onPhotoTap,
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(post.imageUrl, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(post.caption),
          ),
        ],
      ),
    );
  }
}
