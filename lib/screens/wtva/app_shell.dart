import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_bottom_nav.dart';
import '../../utils/account_gate.dart';
import 'check_in_sheet.dart';
import 'discover_screen.dart';
import 'main_tutorial_overlay.dart';
import 'more_screen.dart';
import 'messages_screen.dart';
import 'ranking_screen.dart';

/// Main app shell matching Figma bottom navigation.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Bottom nav index: 0 Discover, 1 Ranking, 2 FAB, 3 Messages, 4 More
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
  }

  Future<void> _maybeShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('wtva_main_tutorial_done') == true) return;
    if (!mounted) return;
    await MainTutorialOverlay.showIfNeeded(context, onDone: () async {
      await prefs.setBool('wtva_main_tutorial_done', true);
    });
  }

  Widget get _body {
    switch (_navIndex) {
      case 1:
        return const RankingScreen();
      case 3:
        return const MessagesScreen();
      case 4:
        return const MoreScreen();
      case 0:
      default:
        return const DiscoverScreen();
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
      bottomNavigationBar: WtvaBottomNav(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index == 2) return;
          setState(() => _navIndex = index);
        },
        onCheckIn: _openCheckIn,
      ),
    );
  }

  Future<void> _openCheckIn() async {
    if (!await AccountGate.requireSignIn(context)) return;
    if (!mounted) return;
    CheckInSheet.show(context);
  }
}
