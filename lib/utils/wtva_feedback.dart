import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/figma_theme.dart';

void showWtvaSnack(BuildContext context, String message, {IconData? icon}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: WtvaColors.dark400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: WtvaColors.neutral50, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

Future<void> showWtvaActionSheet(
  BuildContext context, {
  required String title,
  required List<(String label, IconData icon, VoidCallback onTap)> actions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: WtvaColors.dark400,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...actions.map(
              (a) => ListTile(
                leading: Icon(a.$2, color: WtvaColors.neutral200),
                title: Text(a.$1),
                onTap: () {
                  Navigator.pop(ctx);
                  a.$3();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> copyToClipboard(BuildContext context, String text, {String? message}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    showWtvaSnack(context, message ?? 'Copied to clipboard', icon: Icons.check);
  }
}
