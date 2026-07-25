import 'package:flutter/foundation.dart';

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

  /// Create split group, email guests, return waiting-room details (host may pay later).
  Future<VibeSplitGroupCreated> sendSplitRequests({
    required String packageId,
    required int partySize,
    required List<String> stopOfferIds,
    required String startsOn,
    required int payerCount,
    required List<String> guestEmails,
    String splitMode = 'even',
    List<int>? amountCents,
    int expiresInMinutes = 1440,
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
    if (guestEmails.length != payerCount - 1) {
      throw StateError('Add an email for each friend');
    }

    final token =
        SupabaseBootstrap.client?.auth.currentSession?.accessToken ?? '';
    if (token.isEmpty) {
      throw StateError('Sign in to continue.');
    }

    return _api.createVibeSplitGroup(
      packageId: packageId,
      partySize: partySize,
      stopOfferIds: stopOfferIds,
      startsOn: startsOn,
      payerCount: payerCount,
      guestEmails: guestEmails,
      splitMode: splitMode,
      amountCents: amountCents,
      expiresInMinutes: expiresInMinutes,
    );
  }

  Future<String> payShare({
    required String groupId,
    required String shareId,
    void Function(String stage)? onStage,
  }) async {
    final token =
        SupabaseBootstrap.client?.auth.currentSession?.accessToken ?? '';
    if (token.isEmpty) {
      throw StateError('Sign in to continue.');
    }

    void stage(String s) {
      debugPrint('payShare → $s');
      onStage?.call(s);
    }

    stage('Loading Stripe…');
    await StripeBootstrap.ensureReady();

    stage('Starting payment…');
    final intent = await _api.createVibeShareIntent(
      groupId: groupId,
      shareId: shareId,
    );
    debugPrint('payShare → got PI ${intent.paymentIntentId}');

    stage('Opening card form…');
    await StripeBootstrap.presentPaymentSheet(
      clientSecret: intent.clientSecret,
    );

    stage('Confirming…');
    return _api.confirmVibeSharePayment(intent.paymentIntentId);
  }
}
