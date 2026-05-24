import 'package:flutter/material.dart';
import '../../services/drivers_repository.dart';
import '../../theme/figma_theme.dart';

class DriverCompanyCard extends StatelessWidget {
  const DriverCompanyCard({
    super.key,
    required this.company,
    this.onTap,
  });

  final DriverCompanyRecord company;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
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
                  width: 72,
                  height: 72,
                  child: company.imageUrl != null && company.imageUrl!.isNotEmpty
                      ? Image.network(
                          company.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    if (company.city != null && company.city!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        company.city!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: WtvaColors.neutral300,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (company.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        company.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: WtvaColors.neutral300,
                          height: 1.35,
                        ),
                      ),
                    ],
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

  Widget _placeholder() {
    return Container(
      color: WtvaColors.dark300,
      child: const Icon(Icons.directions_car_outlined, color: WtvaColors.neutral300, size: 28),
    );
  }
}
