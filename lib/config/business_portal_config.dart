/// Business web API base URL for mobile event submission + Stripe.
///
/// Override at build time: `--dart-define=BUSINESS_API_URL=https://business.wherethevibesat.com`
///
/// Android emulator → host machine: `http://10.0.2.2:3002`
class BusinessPortalConfig {
  BusinessPortalConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'BUSINESS_API_URL',
    defaultValue: 'https://business.wherethevibesat.com',
  );
}
