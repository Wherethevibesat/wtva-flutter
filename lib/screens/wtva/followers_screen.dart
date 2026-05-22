import 'package:flutter/material.dart';
import '../../data/mock_social_data.dart';
import '../../theme/figma_theme.dart';
import 'profile/user_profile_screen.dart';

class FollowersScreen extends StatelessWidget {
  final String userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Followers', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: MockSocialData.followers.length,
        itemBuilder: (context, i) {
          final u = MockSocialData.followers[i];
          return _UserRow(
            user: u,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserProfileScreen(user: u)),
            ),
          );
        },
      ),
    );
  }
}

class FollowingScreen extends StatelessWidget {
  final String userId;

  const FollowingScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Following', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: MockSocialData.following.length,
        itemBuilder: (context, i) {
          final u = MockSocialData.following[i];
          return _UserRow(
            user: u,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserProfileScreen(user: u)),
            ),
          );
        },
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final SocialUser user;
  final VoidCallback onTap;

  const _UserRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null ? Text(user.name[0]) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('@${user.username}', style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
                  ],
                ),
              ),
              if (user.followsYou)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WtvaColors.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Follows you', style: TextStyle(fontSize: 10, color: WtvaColors.accentGreen)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
