import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/mock_venue_store.dart';
import '../../services/check_in_repository.dart';
import '../../services/ranking_service.dart';
import '../../theme/figma_theme.dart';
import '../../utils/ranking_award_feedback.dart';
import '../../utils/wtva_feedback.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';
import 'check_in_create_post_screen.dart';
import 'check_in_share_sheet.dart';
import 'venue_detail_screen.dart';

/// Active check-in at a venue (Figma check-in flow after choosing place).
class ActiveCheckInScreen extends StatefulWidget {
  final String venueId;
  final bool fromPost;

  const ActiveCheckInScreen({
    super.key,
    required this.venueId,
    this.fromPost = false,
  });

  @override
  State<ActiveCheckInScreen> createState() => _ActiveCheckInScreenState();
}

class _ActiveCheckInScreenState extends State<ActiveCheckInScreen> {
  late DateTime _startedAt;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _elapsed = Duration.zero;
    _bootstrapCheckIn();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  Future<void> _bootstrapCheckIn() async {
    await CheckInRepository.instance.startCheckIn(venueId: widget.venueId);
    if (!mounted) return;
    final detail = MockVenueStore.byIdOrThrow(widget.venueId);
    final awards = await RankingService.instance.beginCheckInSession(
      venueId: widget.venueId,
      venueName: detail.venue.name,
      imageUrl: detail.venue.imageUrl,
      includePostBonus: widget.fromPost,
    );
    if (!mounted) return;
    showPointsAwards(context, awards);
  }

  Future<void> _onTick() async {
    if (!mounted) return;
    setState(() => _elapsed = DateTime.now().difference(_startedAt));
    final hourly = await RankingService.instance.awardHourlyIfNeeded(_elapsed);
    if (hourly != null && mounted) {
      showPointsAward(context, hourly);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _elapsedLabel {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60);
    final s = _elapsed.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Future<void> _endCheckIn() async {
    await CheckInRepository.instance.endCheckIn();
    await RankingService.instance.endCheckInSession();
    if (!mounted) return;
    Navigator.pop(context);
    showWtvaSnack(context, 'Check-in ended', icon: Icons.check_circle_outline);
  }

  @override
  Widget build(BuildContext context) {
    final detail = MockVenueStore.byIdOrThrow(widget.venueId);

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Checked In', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        detail.venue.imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                WtvaColors.dark500.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Text(
                          detail.venue.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: WtvaColors.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: WtvaColors.neutral50,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.fromPost ? 'Post live — you\'re checked in' : 'You\'re checked in',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: WtvaColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _elapsedLabel,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: WtvaColors.onPrimary,
                        ),
                      ),
                      Text(
                        'Time at venue',
                        style: TextStyle(fontSize: 12, color: WtvaColors.onPrimary.withValues(alpha: 0.65)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ActionTile(
                  icon: Icons.share_outlined,
                  title: 'Share check-in',
                  subtitle: 'Invite friends to join you',
                  onTap: () => CheckInShareSheet.show(context, venueName: detail.venue.name),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.add_photo_alternate_outlined,
                  title: 'Create post',
                  subtitle: 'Photos, caption & +25 points',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckInCreatePostScreen(venueId: widget.venueId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.groups_outlined,
                  title: 'Venue check-ins',
                  subtitle: 'See who\'s here now',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VenueDetailScreen(venueId: widget.venueId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WtvaColors.dark400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.stars, color: WtvaColors.accentGreen, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stay checked in to earn bonus points every hour',
                          style: TextStyle(fontSize: 13, color: WtvaColors.neutral200),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                WtvaGradientButton(
                  label: 'Share',
                  onPressed: () =>
                      CheckInShareSheet.show(context, venueName: detail.venue.name),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _endCheckIn,
                  child: const Text(
                    'End check-in',
                    style: TextStyle(
                      color: WtvaColors.accentPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: WtvaColors.lavender300),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: WtvaColors.neutral200),
            ],
          ),
        ),
      ),
    );
  }
}
