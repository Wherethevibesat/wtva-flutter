import 'package:flutter/material.dart';
import '../../../data/mock_photos_data.dart';
import '../../../data/mock_social_data.dart';
import '../../../theme/figma_theme.dart';
import '../../../widgets/wtva/wtva_tab_bar.dart';
import '../../../utils/wtva_feedback.dart';
import '../../../utils/wtva_media_viewer.dart';
import '../../../utils/wtva_user_helpers.dart';
import '../chat/chat_conversation_screen.dart';
import '../followers_screen.dart';
import '../../../data/mock_messages_data.dart';

class UserProfileScreen extends StatefulWidget {
  final SocialUser user;
  final bool isSelf;

  const UserProfileScreen({super.key, required this.user, this.isSelf = false});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _tab = 0;
  bool _following = false;

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
                onPressed: () => showWtvaActionSheet(
                  context,
                  title: 'Profile options',
                  actions: [
                    ('Share profile', Icons.share_outlined, () {
                      copyToClipboard(
                        context,
                        'https://wherethevibesat.com/u/${u.username}',
                        message: 'Profile link copied',
                      );
                    }),
                    ('Report', Icons.flag_outlined, () {
                      showWtvaSnack(context, 'Report submitted (demo)');
                    }),
                  ],
                ),
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
                    backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                    child: u.avatarUrl == null ? Text(u.name[0]) : null,
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
                    child: Text(u.rank, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatTap(
                        label: 'Followers',
                        value: '${u.followers}',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FollowersScreen(userId: u.id)),
                        ),
                      ),
                      const SizedBox(width: 24),
                      _StatTap(
                        label: 'Following',
                        value: '${u.following}',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FollowingScreen(userId: u.id)),
                        ),
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
                            onPressed: () {
                              setState(() => _following = !_following);
                              showWtvaSnack(
                                context,
                                _following ? 'Following ${u.name}' : 'Unfollowed ${u.name}',
                                icon: _following ? Icons.person_add : Icons.person_remove,
                              );
                            },
                            child: Text(_following ? 'Following' : 'Follow'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            final thread = chatThreadForUser(u.name) ??
                                ChatThread(
                                  id: 'new-${u.id}',
                                  name: u.name,
                                  lastMessage: 'Say hi to ${u.name}',
                                  timeAgo: 'Now',
                                  avatarUrl: u.avatarUrl,
                                );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatConversationScreen(thread: thread),
                              ),
                            );
                          },
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = MockPhotosData.items[i % MockPhotosData.items.length];
                    return GestureDetector(
                      onTap: () => openWtvaMediaViewer(context, item),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(item.imageUrl, fit: BoxFit.cover),
                      ),
                    );
                  },
                  childCount: MockPhotosData.items.length,
                ),
              ),
            )
          else if (_tab == 1)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = MockPhotosData.videos[i % MockPhotosData.videos.length];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: GestureDetector(
                      onTap: () => openWtvaMediaViewer(context, item),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.imageUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const Positioned.fill(
                            child: Center(child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white70)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: 4,
              ),
            )
          else
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Nightlife explorer sharing vibes across Houston and beyond.',
                  style: TextStyle(color: WtvaColors.neutral200, height: 1.5),
                ),
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

class _StatTap extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _StatTap({required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _Stat(label: label, value: value),
    );
  }
}
