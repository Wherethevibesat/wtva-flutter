import 'package:flutter/material.dart';
import '../../../data/mock_social_data.dart';
import '../../../theme/figma_theme.dart';
import '../../../widgets/wtva/wtva_tab_bar.dart';
import '../../../utils/wtva_feedback.dart';

class UserProfileScreen extends StatefulWidget {
  final SocialUser user;
  final bool isSelf;

  const UserProfileScreen({super.key, required this.user, this.isSelf = false});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: WtvaColors.dark500,
            title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  final actions = <(String, IconData, VoidCallback)>[
                    (
                      'Share profile',
                      Icons.share_outlined,
                      () {
                        copyToClipboard(
                          context,
                          'https://wherethevibesat.com/u/${u.username}',
                          message: 'Profile link copied',
                        );
                      },
                    ),
                  ];
                  if (!widget.isSelf) {
                    actions.add((
                      'Report',
                      Icons.flag_outlined,
                      () {
                        showWtvaSnack(
                          context,
                          'Reporting isn’t available in the app yet.',
                        );
                      },
                    ));
                  }
                  showWtvaActionSheet(
                    context,
                    title: 'Profile options',
                    actions: actions,
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: WtvaColors.dark300,
                    backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                    child: u.avatarUrl == null
                        ? Text(
                            u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(u.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('@${u.username}', style: const TextStyle(color: WtvaColors.neutral300)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: WtvaColors.rankBlueGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      u.rank,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Stat(
                        label: 'Followers',
                        value: '${u.followers}',
                      ),
                      const SizedBox(width: 24),
                      _Stat(
                        label: 'Following',
                        value: '${u.following}',
                      ),
                      const SizedBox(width: 24),
                      _Stat(label: 'Points', value: '${u.points}'),
                    ],
                  ),
                  if (!widget.isSelf) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => showWtvaSnack(
                              context,
                              'Following isn’t available yet.',
                            ),
                            child: const Text('Follow'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => showWtvaSnack(
                            context,
                            'Messaging isn’t available yet.',
                          ),
                          child: const Text('Message'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  WtvaTabBar(
                    labels: const ['Photos', 'Videos', 'About'],
                    selectedIndex: _tab,
                    onSelected: (i) => setState(() => _tab = i),
                  ),
                ],
              ),
            ),
          ),
          if (_tab == 0)
            const SliverToBoxAdapter(child: _EmptyMedia(label: 'No photos yet'))
          else if (_tab == 1)
            const SliverToBoxAdapter(child: _EmptyMedia(label: 'No videos yet'))
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.isSelf
                      ? 'Your WTVA profile. Check in at venues to earn points and climb the ranks.'
                      : '${u.name} is on Where The Vibes At.',
                  style: const TextStyle(color: WtvaColors.neutral200, height: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyMedia extends StatelessWidget {
  const _EmptyMedia({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        children: [
          Icon(Icons.photo_outlined, size: 40, color: WtvaColors.neutral300.withValues(alpha: 0.8)),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: WtvaColors.neutral300,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
      ],
    );
  }
}
