import 'package:flutter/material.dart';
import '../../config/app_brand.dart';

/// Shared WTVA logo image used on splash, mode picker, and branded headers.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 56,
  });

  final double height;

  static const String assetPath = AppBrand.logoAsset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: AppBrand.name,
      filterQuality: FilterQuality.high,
    );
  }
}
