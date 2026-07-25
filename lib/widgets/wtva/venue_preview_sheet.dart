import 'package:flutter/material.dart';
import '../../data/mock_venue_store.dart';
import '../../services/venue_repository.dart';
import '../../theme/figma_theme.dart';
import '../../utils/vibe_copy.dart';

/// In-flow venue peek (matches web VenuePreviewModal) — does not leave booking.
Future<void> showVenuePreviewSheet(
  BuildContext context, {
  required String? venueId,
  required String venueName,
}) async {
  if (venueId == null || venueId.isEmpty) return;

  await VenueRepository.instance.hydrate();
  if (!context.mounted) return;

  final detail = MockVenueStore.byId(venueId);
  final image = detail?.venue.imageUrl;
  final address = detail?.address;
  final category = detail?.category;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: WtvaColors.dark400,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WtvaColors.night200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    vibeImageUrl(image),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: WtvaColors.dark500,
                      alignment: Alignment.center,
                      child: const Icon(Icons.storefront_outlined,
                          color: WtvaColors.neutral300),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                venueName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: WtvaColors.neutral50,
                ),
              ),
              if (category != null && category.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 13,
                    color: WtvaColors.accentPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: WtvaColors.neutral300,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: WtvaColors.accentPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Back to vibe',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Tappable venue name → [showVenuePreviewSheet].
class VenueNameButton extends StatelessWidget {
  const VenueNameButton({
    super.key,
    required this.name,
    this.venueId,
    this.style,
  });

  final String name;
  final String? venueId;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: WtvaColors.accentPurple,
        );
    if (venueId == null || venueId!.isEmpty) {
      return Text(name, style: base.copyWith(color: WtvaColors.neutral300));
    }
    return GestureDetector(
      onTap: () => showVenuePreviewSheet(
        context,
        venueId: venueId,
        venueName: name,
      ),
      child: Text(
        name,
        style: base.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: WtvaColors.accentPurple.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
