import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_brand.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';
import 'auth_gate.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static const prefsKey = 'wtva_onboarding_complete';

  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.explore,
      title: 'Find the vibe',
      body: 'Discover bars, clubs, and restaurants near you — see what’s live tonight.',
      gradient: WtvaColors.buttonGradient,
    ),
    _Slide(
      icon: Icons.add_location_alt,
      title: 'Check in & earn',
      body: 'Check in at venues, collect points, and climb the ranks to unlock perks.',
      gradient: WtvaColors.fabGradient,
    ),
    _Slide(
      icon: Icons.emoji_events,
      title: 'Rank up',
      body: 'From Vibee to Influencer — get noticed by venues and paid invites.',
      gradient: WtvaColors.rankBlueGradient,
    ),
  ];

  Future<void> _finish() async {
    await WelcomeScreen.markComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip', style: TextStyle(color: WtvaColors.neutral300)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: slide.gradient,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(slide.icon, size: 56, color: WtvaColors.onPrimary),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: WtvaColors.neutral50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: WtvaColors.neutral200,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => Container(
                  width: i == _page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: i == _page ? WtvaColors.buttonGradient : null,
                    color: i == _page ? null : WtvaColors.night200,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: WtvaGradientButton(
                label: _page == _slides.length - 1 ? 'Get started' : 'Next',
                onPressed: () {
                  if (_page < _slides.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  } else {
                    _finish();
                  }
                },
              ),
            ),
            Text(
              AppBrand.name,
              style: const TextStyle(fontSize: 11, color: WtvaColors.neutral300),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  final Gradient gradient;

  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    required this.gradient,
  });
}
