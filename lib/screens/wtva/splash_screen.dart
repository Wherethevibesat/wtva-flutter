import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import '../../services/business_service.dart';
import '../../services/favorites_service.dart';
import '../../services/ranking_service.dart';
import '../../services/venue_repository.dart';
import '../../services/app_mode_service.dart';
import '../../services/user_service.dart';
import '../../widgets/wtva/brand_logo.dart';
import 'app_launcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      AppModeService.instance.load(),
      UserService().initializeUser(),
      BusinessService.instance.load(),
      VenueRepository.instance.hydrate(),
      FavoritesService.instance.load(),
      RankingService.instance.load(),
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]);
    if (!mounted) return;
    await _goNext();
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootAppLauncher()),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // White logo plate reads cleanly on the dark splash.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: BrandLogo(height: 64),
                ),
              ),
            ),
            const SizedBox(height: 48),
            RotationTransition(
              turns: _spin,
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: WtvaColors.neutral50,
                  backgroundColor: WtvaColors.night200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
