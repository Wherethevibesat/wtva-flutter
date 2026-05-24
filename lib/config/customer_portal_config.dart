/// Customer web API base URL for ticket checkout + Stripe.
///
/// Override: `--dart-define=CUSTOMER_API_URL=https://wherethevibesat.com`
///
/// Android emulator → host: `http://10.0.2.2:3001`
class CustomerPortalConfig {
  CustomerPortalConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'CUSTOMER_API_URL',
    defaultValue: 'https://wherethevibesat.com',
  );
}
