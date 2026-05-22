import 'package:flutter/material.dart';

/// Named rank unlocked at a lifetime points threshold.
class RankTier {
  final String name;
  final int pointsRequired;
  final String description;
  final String? payRate;
  final Gradient? iconGradient;
  final Gradient? cardGradient;
  final IconData icon;

  const RankTier({
    required this.name,
    required this.pointsRequired,
    required this.description,
    this.payRate,
    this.iconGradient,
    this.cardGradient,
    required this.icon,
  });
}
