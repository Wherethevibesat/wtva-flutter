import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import '../../utils/wtva_feedback.dart';

class CheckInShareSheet extends StatelessWidget {
  final String venueName;

  const CheckInShareSheet({super.key, required this.venueName});

  static Future<void> show(BuildContext context, {required String venueName}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckInShareSheet(venueName: venueName),
    );
  }

  @override
  Widget build(BuildContext context) {
    const channels = [
      (Icons.chat_bubble_outline, 'Message'),
      (Icons.copy, 'Copy link'),
      (Icons.camera_alt_outlined, 'Instagram'),
      (Icons.more_horiz, 'More'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 63,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share at $venueName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: channels.map((c) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      final link = 'https://wherethevibesat.com/check-in/${venueName.replaceAll(' ', '-').toLowerCase()}';
                      if (c.$2 == 'Copy link') {
                        copyToClipboard(context, link, message: 'Check-in link copied');
                      } else {
                        showWtvaSnack(context, 'Shared via ${c.$2} (demo)', icon: c.$1);
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: WtvaColors.dark300,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(c.$1, color: WtvaColors.neutral50),
                        ),
                        const SizedBox(height: 8),
                        Text(c.$2, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
