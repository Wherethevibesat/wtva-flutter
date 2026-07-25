import '../services/customer_portal_api.dart';
import '../services/stripe_bootstrap.dart';
import '../services/supabase_bootstrap.dart';

class NightPackageCheckoutService {
  NightPackageCheckoutService._();
  static final NightPackageCheckoutService instance =
      NightPackageCheckoutService._();

  final _api = CustomerPortalApi.instance;

  Future<NightPackagePaymentIntent> purchase({
    required String packageId,
    required int partySize,
    required List<String> stopOfferIds,
    required String startsOn,
  }) async {
    if (stopOfferIds.isEmpty) {
      throw StateError('Add at least one stop to your vibe');
    }
    if (startsOn.isEmpty) {
      throw StateError('Pick a start date for your vibe');
    }

    final token =
        SupabaseBootstrap.client?.auth.currentSession?.accessToken ?? '';
    if (token.isEmpty) {
      throw StateError('Sign in to continue.');
    }

    await StripeBootstrap.ensureReady();

    final intent = await _api.createNightPackageIntent(
      packageId: packageId,
      partySize: partySize,
      stopOfferIds: stopOfferIds,
      startsOn: startsOn,
    );

    await StripeBootstrap.presentPaymentSheet(
      clientSecret: intent.clientSecret,
    );

    await _api.confirmNightPackagePayment(intent.paymentIntentId);
    return intent;
  }

  /// Host creates a split group, pays their share, returns invite details.
  Future<({VibeSplitGroupCreated group, String status})> startSplitAndPayHost({
    required String packageId,
    required int partySize,
    required List<String> stopOfferIds,
    required String startsOn,
    required int payerCount,
  }) async {
    if (stopOfferIds.isEmpty) {
      throw StateError('Add at least one stop to your vibe');
    }
    if (startsOn.isEmpty) {
      throw StateError('Pick a start date for your vibe');
    }
    if (payerCount < 2) {
      throw StateError('Split needs at least 2 people');
    }

    final token =
        SupabaseBootstrap.client?.auth.currentSession?.accessToken ?? '';
    if (token.isEmpty) {
      throw StateError('Sign in to continue.');
    }

    await StripeBootstrap.ensureReady();

    final group = await _api.createVibeSplitGroup(
      packageId: packageId,
      partySize: partySize,
      stopOfferIds: stopOfferIds,
      startsOn: startsOn,
      payerCount: payerCount,
    );

    final intent = await _api.createVibeShareIntent(
      groupId: group.groupId,
      shareId: group.hostShareId,
    );

    await StripeBootstrap.presentPaymentSheet(
      clientSecret: intent.clientSecret,
    );

    final status = await _api.confirmVibeSharePayment(intent.paymentIntentId);
    return (group: group, status: status);
  }

  Future<String> payShare({
    required String groupId,
    required String shareId,
  }) async {
    final token =
        SupabaseBootstrap.client?.auth.currentSession?.accessToken ?? '';
    if (token.isEmpty) {
      throw StateError('Sign in to continue.');
    }

    await StripeBootstrap.ensureReady();

    final intent = await _api.createVibeShareIntent(
      groupId: groupId,
      shareId: shareId,
    );

    await StripeBootstrap.presentPaymentSheet(
      clientSecret: intent.clientSecret,
    );

    return _api.confirmVibeSharePayment(intent.paymentIntentId);
  }
}
