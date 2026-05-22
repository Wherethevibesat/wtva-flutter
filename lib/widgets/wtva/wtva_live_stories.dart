import 'package:flutter/material.dart';
import '../../models/venue.dart';
import '../../theme/figma_theme.dart';

class WtvaLiveStories extends StatelessWidget {
  final List<LiveStory> stories;
  final void Function(LiveStory story)? onStoryTap;

  const WtvaLiveStories({super.key, required this.stories, this.onStoryTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _LiveStoryTile(
          story: stories[index],
          onTap: onStoryTap != null ? () => onStoryTap!(stories[index]) : null,
        ),
      ),
    );
  }
}

class _LiveStoryTile extends StatelessWidget {
  final LiveStory story;
  final VoidCallback? onTap;

  const _LiveStoryTile({required this.story, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
      width: 88,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [WtvaColors.neutral50, WtvaColors.neutral300],
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Image.network(
                    story.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: WtvaColors.dark300),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: WtvaColors.neutral50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: WtvaColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            story.userName.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: WtvaColors.neutral200,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
