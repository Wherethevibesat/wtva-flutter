import 'package:flutter/material.dart';
import '../../models/venue.dart';
import '../../services/favorites_service.dart';
import '../../theme/figma_theme.dart';
import '../../theme/wtva_icons.dart';
import '../../utils/wtva_feedback.dart';

/// Compact venue row — Posh-style poster + metadata (fits more on Discover).
class WtvaVenueCard extends StatefulWidget {
  final Venue venue;
  final VoidCallback? onTap;

  const WtvaVenueCard({super.key, required this.venue, this.onTap});

  @override
  State<WtvaVenueCard> createState() => _WtvaVenueCardState();
}

class _WtvaVenueCardState extends State<WtvaVenueCard> {
  static const _posterWidth = 76.0;
  static const _posterHeight = 92.0;

  late bool _fav;

  @override
  void initState() {
    super.initState();
    _fav = FavoritesService.instance.isFavorite(widget.venue.id);
  }

  Future<void> _toggleFav() async {
    final on = await FavoritesService.instance.toggle(widget.venue.id);
    if (!mounted) return;
    setState(() => _fav = on);
    showWtvaSnack(
      context,
      on ? 'Saved to favorites' : 'Removed from favorites',
      icon: on ? Icons.favorite_border : Icons.favorite_border,
    );
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WtvaColors.night200.withValues(alpha: 0.55)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: _posterWidth,
                  height: _posterHeight,
                  child: Image.network(
                    venue.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: WtvaColors.dark300,
                      child: WtvaIcons.icon(Icons.image_outlined, size: WtvaIcons.md, color: WtvaColors.neutral300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: _posterHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        venue.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.2,
                          color: WtvaColors.neutral50,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          WtvaIcons.icon(Icons.star_outline, size: WtvaIcons.sm, color: WtvaColors.neutral300),
                          const SizedBox(width: 4),
                          Text(
                            venue.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: WtvaColors.neutral300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          WtvaIcons.icon(Icons.near_me_outlined, size: WtvaIcons.sm, color: WtvaColors.neutral300),
                          const SizedBox(width: 4),
                          Text(
                            '${venue.distanceMiles} mi away',
                            style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                height: _posterHeight,
                child: IconButton(
                  onPressed: _toggleFav,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    _fav ? Icons.favorite : Icons.favorite_border,
                    size: WtvaIcons.md,
                    color: _fav ? WtvaColors.neutral50 : WtvaColors.neutral300,
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
