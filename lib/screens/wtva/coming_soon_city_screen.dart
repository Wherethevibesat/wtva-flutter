import 'package:flutter/material.dart';
import '../../data/wtva_cities.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';
import 'request_city_sheet.dart';

class ComingSoonCityScreen extends StatelessWidget {
  const ComingSoonCityScreen({super.key, required this.city});

  final WtvaCity city;

  static const _highlights = [
    'Curated events, day parties, and club nights',
    'Venue profiles, hours, and VIP tables',
    'Check in and save your favorite spots',
    'A concierge that finds your vibe',
  ];

  @override
  Widget build(BuildContext context) {
    final live = WtvaCities.defaultCity;
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: Text(city.label),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: WtvaColors.dark400,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: WtvaColors.night200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: WtvaColors.accentPurple),
                  const SizedBox(width: 6),
                  Text(
                    city.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: WtvaColors.accentPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: WtvaColors.neutral50,
              ),
              children: [
                const TextSpan(text: "We're bringing the vibes to "),
                TextSpan(
                  text: city.name,
                  style: const TextStyle(color: WtvaColors.accentPurple),
                ),
                const TextSpan(text: ' soon.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Where The Vibes At is expanding, and ${city.name} is next up. "
            "It's not live just yet — request early access and we'll let you know the moment we launch.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: WtvaColors.neutral200,
            ),
          ),
          const SizedBox(height: 24),
          WtvaGradientButton(
            label: 'Notify me when we launch',
            onPressed: () => RequestCitySheet.show(
              context,
              initialCity: city.label,
              source: 'coming_soon',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Explore ${live.name} (live now)'),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WtvaColors.dark400,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: WtvaColors.night200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18, color: WtvaColors.accentPurple),
                    const SizedBox(width: 8),
                    Text(
                      'What to expect in ${city.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final item in _highlights) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 7),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: WtvaColors.accentPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: WtvaColors.neutral200,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
