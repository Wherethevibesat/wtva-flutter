import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'config/app_brand.dart';
import 'screens/wtva/splash_screen.dart';
import 'theme/figma_theme.dart';
import 'services/push_notification_service.dart';
import 'services/stripe_bootstrap.dart';
import 'services/supabase_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  // Prefetch publishable key so PaymentSheet isn’t cold on first Pay.
  // ignore: unawaited_futures
  StripeBootstrap.warmUp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService.instance.initialize();
  runApp(const WhereTheVibesAtApp());
}

class WhereTheVibesAtApp extends StatelessWidget {
  const WhereTheVibesAtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppBrand.name,
      theme: WtvaTheme.light,
      darkTheme: WtvaTheme.light,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
