import 'package:flutter/material.dart';

import 'figma_theme.dart';

/// Thin outlined icons — Posh / Partiful style.
abstract final class WtvaIcons {
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 22;

  static Icon icon(
    IconData data, {
    double size = md,
    Color? color,
  }) =>
      Icon(data, size: size, color: color ?? WtvaColors.neutral200);

  static IconThemeData theme({Color? color, double size = md}) => IconThemeData(
        color: color ?? WtvaColors.neutral200,
        size: size,
      );
}
