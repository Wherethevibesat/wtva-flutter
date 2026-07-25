import 'package:flutter/material.dart';

import '../services/customer_portal_api.dart';
import '../services/stripe_bootstrap.dart';
import '../services/supabase_bootstrap.dart';
import '../widgets/wtva/stripe_collect_payment.dart';

class NightPackageCheckoutService {
  NightPackageCheckoutService._();
  static final NightPackageCheckoutService instance =
      NightPackageCheckoutService._();

  final _api = CustomerPortalApi.instance;

  Future<NightPackagePaymentIntent> purchase({
    required BuildContext context,
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

    await StripeBootstrap.ensureReady().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw StateError('Stripe took too long. Try again.'),
    );

    final intent = await _api
        .createNightPackageIntent(
          packageId: packageId,
          partySize: partySize,
          stopOfferIds: stopOfferIds,
          startsOn: startsOn,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () =>
              throw StateError('Could not start payment. Check your connection.'),
        );

    if (!context.mounted) throw StateError('Payment cancelled');
    await collectStripePayment(
      context,
      clientSecret: intent.clientSecret,
      amountLabel: _money(intent.amount),
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
    required BuildContext context,
    required String groupId,
    required String shareId,
    required double amount,
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
    await StripeBootstrap.ensureReady().timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw StateError('Stripe took too long. Try again.'),
    );

    stage('Starting payment…');
    final intent = await _api
        .createVibeShareIntent(groupId: groupId, shareId: shareId)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () =>
              throw StateError('Could not start payment. Check your connection.'),
        );

    stage('Opening checkout…');
    if (!context.mounted) throw StateError('Payment cancelled');
    await collectStripePayment(
      context,
      clientSecret: intent.clientSecret,
      amountLabel: _money(intent.amount > 0 ? intent.amount : amount),
    );

    stage('Confirming…');
    return _api.confirmVibeSharePayment(intent.paymentIntentId);
  }

  String _money(double dollars) {
    final whole = dollars == dollars.roundToDouble();
    return '\$${dollars.toStringAsFixed(whole ? 0 : 2)}';
  }
}
