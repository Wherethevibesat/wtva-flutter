import 'package:flutter/material.dart';
import '../../config/app_brand.dart';
import '../../theme/figma_theme.dart';
import '../../services/business_service.dart';
import '../../services/favorites_service.dart';
import '../../services/ranking_service.dart';
import '../../services/venue_repository.dart';
import '../../services/app_mode_service.dart';
import '../../services/user_service.dart';
import '../../widgets/wtva/brand_logo.dart';
import '../../widgets/wtva/wtva_brand_backdrop.dart';
import 'app_launcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WtvaBrandBackdrop(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.96, end: 1.0).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: WtvaColors.accentPink.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const BrandLogo(height: 64),
                  ),
                ),
                const SizedBox(height: 28),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFE9D5FF),
                      Color(0xFFF0ABFC),
                      Color(0xFFF9A8D4),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    AppBrand.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white.withValues(alpha: 0.95),
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
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
