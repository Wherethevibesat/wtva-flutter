/// Customer web API base URL for ticket checkout, concierge, and tips.
///
/// Override: `--dart-define=CUSTOMER_API_URL=https://www.wherethevibesat.com`
///
/// Use the `www` host — apex `wherethevibesat.com` 308-redirects and Dart's
/// `http` client often fails POST after that redirect (Concierge → unavailable).
///
/// Local: `--dart-define=CUSTOMER_API_URL=http://127.0.0.1:3001`
/// Android emulator → host: `http://10.0.2.2:3001`
class CustomerPortalConfig {
  CustomerPortalConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'CUSTOMER_API_URL',
    defaultValue: 'https://www.wherethevibesat.com',
  );
}
