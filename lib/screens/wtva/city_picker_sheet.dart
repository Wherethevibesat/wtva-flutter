import 'package:flutter/material.dart';
import '../../data/wtva_cities.dart';
import '../../theme/figma_theme.dart';
import 'coming_soon_city_screen.dart';
import 'request_city_sheet.dart';

class CityPickerSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const CityPickerSheet({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WtvaColors.dark400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CityPickerSheet(selected: selected, onSelected: onSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                'Choose city',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH - 80),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: WtvaCities.all.length,
                itemBuilder: (context, i) {
                  final city = WtvaCities.all[i];
                  final on = city.label == selected;
                  return ListTile(
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: on ? WtvaColors.accentPurple : WtvaColors.neutral300,
                    ),
                    title: Text(
                      city.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: on ? WtvaColors.accentPurple : WtvaColors.neutral50,
                      ),
                    ),
                    trailing: city.live
                        ? (on
                            ? const Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: WtvaColors.accentPurple,
                                ),
                              )
                            : null)
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: WtvaColors.dark300,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'SOON',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: WtvaColors.neutral300,
                              ),
                            ),
                          ),
                    onTap: () {
                      Navigator.pop(context);
                      if (city.live) {
                        onSelected(city.label);
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ComingSoonCityScreen(city: city),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: WtvaColors.night200),
            ListTile(
              leading: const Icon(Icons.add, color: WtvaColors.accentPurple),
              title: const Text(
                'Request a city',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: WtvaColors.accentPurple,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                RequestCitySheet.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
