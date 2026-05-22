import 'package:flutter/material.dart';
import 'config/app_brand.dart';
import 'screens/wtva/splash_screen.dart';
import 'theme/figma_theme.dart';
import 'services/supabase_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  runApp(const WhereTheVibesAtApp());
}

class WhereTheVibesAtApp extends StatelessWidget {
  const WhereTheVibesAtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppBrand.name,
      theme: WtvaTheme.dark,
      darkTheme: WtvaTheme.dark,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
