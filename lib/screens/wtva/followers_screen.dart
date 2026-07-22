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
      body: MockSocialData.followers.isEmpty
          ? const _EmptySocial(label: 'No followers yet')
          : ListView.builder(
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
      body: MockSocialData.following.isEmpty
          ? const _EmptySocial(label: 'Not following anyone yet')
          : ListView.builder(
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

class _EmptySocial extends StatelessWidget {
  const _EmptySocial({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label, style: const TextStyle(color: WtvaColors.neutral300)),
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
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(user.name.isNotEmpty ? user.name[0] : '?')
                : null,
          ),
          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('@${user.username}', style: const TextStyle(color: WtvaColors.neutral300)),
          trailing: const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
        ),
      ),
    );
  }
}
