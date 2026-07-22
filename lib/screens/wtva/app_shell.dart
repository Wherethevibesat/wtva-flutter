import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_bottom_nav.dart';
import '../../utils/account_gate.dart';
import 'check_in_sheet.dart';
import 'concierge_sheet.dart';
import 'events_browse_screen.dart';
import 'main_tutorial_overlay.dart';
import 'messages_screen.dart';
import 'tonight_screen.dart';
import 'venues_browse_screen.dart';

/// Main app shell — Tonight / Events / Check In / Inbox / Venues.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// 0 Tonight, 1 Events, 2 FAB, 3 Inbox, 4 Venues
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
        return const EventsBrowseScreen(embedded: true);
      case 3:
        return const MessagesScreen();
      case 4:
        return const VenuesBrowseScreen(embedded: true);
      case 0:
      default:
        return const TonightScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: _body,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _AskConciergeFab(
        onPressed: () => ConciergeSheet.show(context),
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

class _AskConciergeFab extends StatelessWidget {
  const _AskConciergeFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: WtvaColors.buttonGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: WtvaColors.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Ask Concierge',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
