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
  int _tabIndex = 0;
  bool _favorited = false;

  @override
  void initState() {
    super.initState();
    _favorited = FavoritesService.instance.isFavorite(widget.venueId);
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

  @override
  Widget build(BuildContext context) {
    final detail = MockVenueStore.byIdOrThrow(widget.venueId);
    final v = detail.venue;

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: WtvaColors.dark500,
                leading: _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
                actions: [
                  _circleBtn(
                    _favorited ? Icons.favorite : Icons.favorite_border,
                    _toggleFavorite,
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        v.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: WtvaColors.dark300),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              WtvaColors.dark500.withValues(alpha: 0.95),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: WtvaColors.neutral50,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StarRating(rating: v.rating, fullStars: v.fullStars, halfStar: v.halfStar),
                          const SizedBox(width: 8),
                          Text(
                            v.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: WtvaColors.neutral50,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: WtvaColors.dark400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${detail.checkInCount} Check-Ins',
                              style: const TextStyle(fontSize: 12, color: WtvaColors.neutral200),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            detail.isOpen ? Icons.circle : Icons.circle_outlined,
                            size: 10,
                            color: detail.isOpen ? WtvaColors.neutral50 : WtvaColors.neutral300,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            detail.hoursLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: detail.isOpen ? WtvaColors.neutral50 : WtvaColors.neutral300,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(detail.category, style: const TextStyle(color: WtvaColors.neutral300)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => VenueServiceOptionsSheet.show(context, services: detail.services),
                        child: _ServicesRow(services: detail.services),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        detail.description,
                        style: const TextStyle(color: WtvaColors.neutral200, height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: WtvaColors.neutral300),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              detail.address,
                              style: const TextStyle(color: WtvaColors.neutral300, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${v.distanceMiles} mi',
                            style: const TextStyle(color: WtvaColors.neutral200, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _DetailTabs(
                        index: _tabIndex,
                        onChanged: (i) => setState(() => _tabIndex = i),
                      ),
                      const SizedBox(height: 16),
                      if (_tabIndex == 0) _OverviewTab(detail: detail)
                      else if (_tabIndex == 1) ...[
                        _ViewAllRow(
                          label: 'See all check-ins',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VenueAllCheckInsScreen(venueId: widget.venueId),
                            ),
                          ),
                        ),
                        ...detail.recentCheckIns.map((p) => Padding(
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
                            )),
                      ] else ...[
                        _ViewAllRow(
                          label: 'See all photos',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VenueAllPhotosScreen(venueId: widget.venueId),
                            ),
                          ),
                        ),
                        _PhotosTab(imageUrl: v.imageUrl, venueId: widget.venueId),
                        const SizedBox(height: 12),
                        _ViewAllRow(
                          label: 'See all videos',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VenueAllVideosScreen(venueId: widget.venueId),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: _CheckInFab(
              onTap: () => _openCheckIn(context, detail),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: WtvaColors.dark400,
          border: Border(top: BorderSide(color: WtvaColors.night200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: Icons.directions,
                label: 'Directions',
                onPressed: () async {
                  final ok = await openMapsSearch(detail.address);
                  if (!context.mounted) return;
                  if (!ok) showWtvaSnack(context, 'Could not open maps');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionChip(
                icon: Icons.call,
                label: 'Call',
                onPressed: () async {
                  final ok = await openPhoneCall('+17135550100');
                  if (!context.mounted) return;
                  if (!ok) showWtvaSnack(context, 'Could not start call');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: WtvaColors.buttonGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () => _openCheckIn(context, detail),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Check In',
                    style: TextStyle(fontWeight: FontWeight.w700, color: WtvaColors.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCheckIn(BuildContext context, VenueDetail detail) async {
    if (!await AccountGate.requireSignIn(context)) return;
    if (!context.mounted) return;
    await CheckInOptionsSheet.show(
      context,
      venueId: detail.venue.id,
      venueName: detail.venue.name,
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: WtvaColors.night500.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: WtvaColors.neutral50, size: 20),
        ),
      ),
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
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: WtvaColors.fabGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: WtvaColors.accentPurple.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_location_alt, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check In',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: WtvaColors.neutral200),
          ),
        ],
      ),
    );
  }
}

class _ServicesRow extends StatelessWidget {
  final List<String> services;

  const _ServicesRow({required this.services});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              children: services.take(3).map((s) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: WtvaColors.accentGreen),
                    const SizedBox(width: 4),
                    Text(s, style: const TextStyle(fontSize: 13, color: WtvaColors.neutral200)),
                  ],
                );
              }).toList(),
            ),
          ),
          const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
        ],
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _DetailTabs({required this.index, required this.onChanged});

  static const _labels = ['Overview', 'Check-ins', 'Photos'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final selected = i == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: Column(
              children: [
                Text(
                  _labels[i],
                  style: TextStyle(
                    color: selected ? WtvaColors.neutral50 : WtvaColors.neutral200,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: selected ? WtvaColors.buttonGradient : null,
                    color: selected ? null : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final VenueDetail detail;

  const _OverviewTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoTile(
          icon: Icons.calendar_today_outlined,
          title: 'Events',
          subtitle: '3 upcoming this week',
          onTap: () => showWtvaSnack(context, '3 events this week at ${detail.venue.name}', icon: Icons.event),
        ),
        _InfoTile(
          icon: Icons.local_offer_outlined,
          title: 'Offers',
          subtitle: '50% OFF entry — weekends',
          onTap: () => showWtvaSnack(context, 'Weekend entry: 50% off', icon: Icons.local_offer),
        ),
        _InfoTile(
          icon: Icons.groups_outlined,
          title: 'Crowd',
          subtitle: 'Busy after 10 PM',
          onTap: () => showWtvaSnack(context, 'Peak crowd: after 10 PM', icon: Icons.groups),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: WtvaColors.lavender300),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
        ],
      ),
        ),
      ),
    );
  }
}

class _ViewAllRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ViewAllRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(onPressed: onTap, child: Text(label)),
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
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(post.avatarUrl)),
            title: Text(post.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(post.timeAgo, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.more_horiz, color: WtvaColors.neutral300),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.caption),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 18, color: WtvaColors.neutral300),
                    const SizedBox(width: 6),
                    Text('${post.likes}', style: const TextStyle(color: WtvaColors.neutral300)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosTab extends StatelessWidget {
  final String imageUrl;
  final String venueId;

  const _PhotosTab({required this.imageUrl, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(6, (i) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VenuePhotoViewerScreen(imageUrl: imageUrl)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        );
      }),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionChip({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: WtvaColors.neutral200,
        side: const BorderSide(color: WtvaColors.night200),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  final int fullStars;
  final bool halfStar;

  const _StarRating({required this.rating, required this.fullStars, required this.halfStar});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (i < fullStars) {
          icon = Icons.star;
        } else if (i == fullStars && halfStar) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, size: 16, color: WtvaColors.accentGreen);
      }),
    );
  }
}
