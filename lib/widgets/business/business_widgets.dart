import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

class BusinessSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;

  const BusinessSectionTitle({super.key, required this.title, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: const Text(
                'View all',
                style: TextStyle(fontSize: 13, color: WtvaColors.neutral300, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class BusinessCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const BusinessCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class BusinessMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const BusinessMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: WtvaColors.neutral200),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300))
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: WtvaColors.neutral300)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class BusinessFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const BusinessFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? WtvaColors.neutral50 : WtvaColors.dark400,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WtvaColors.night200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? WtvaColors.onPrimary : WtvaColors.neutral200,
          ),
        ),
      ),
    );
  }
}

class BusinessStatRow extends StatelessWidget {
  final String label;
  final String value;

  const BusinessStatRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return BusinessCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: WtvaColors.neutral200)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      ),
    );
  }
}
