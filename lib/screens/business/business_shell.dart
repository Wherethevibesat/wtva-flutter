import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/business/business_bottom_nav.dart';
import 'browse/business_browse_flow.dart';
import 'business_home_screen.dart';
import 'promotions/business_promotions_flow.dart';
import 'settings/business_settings_flow.dart';

class BusinessShell extends StatefulWidget {
  const BusinessShell({super.key});

  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<BusinessShell> {
  int _navIndex = 0;

  Widget get _body {
    switch (_navIndex) {
      case 1:
        return const BusinessBrowseScreen();
      case 2:
        return const BusinessPromotionsScreen();
      case 3:
        return const BusinessMoreScreen();
      case 0:
      default:
        return const BusinessHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: DecoratedBox(decoration: BoxDecoration(gradient: WtvaColors.shineOverlay)),
          ),
          _body,
        ],
      ),
      bottomNavigationBar: BusinessBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}
