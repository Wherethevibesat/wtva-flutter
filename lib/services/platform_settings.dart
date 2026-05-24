class PlatformSettings {
  const PlatformSettings({
    required this.eventSubmissionFee,
    required this.requirePayment,
    required this.autoApproveEvents,
  });

  final double eventSubmissionFee;
  final bool requirePayment;
  final bool autoApproveEvents;

  static const defaults = PlatformSettings(
    eventSubmissionFee: 25,
    requirePayment: true,
    autoApproveEvents: false,
  );

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      eventSubmissionFee: _toDouble(json['event_submission_fee'], defaults.eventSubmissionFee),
      requirePayment: json['require_payment'] as bool? ?? defaults.requirePayment,
      autoApproveEvents: json['auto_approve_events'] as bool? ?? defaults.autoApproveEvents,
    );
  }

  bool get canPayToPublish => eventSubmissionFee > 0;
  bool get canFreeReview => !requirePayment || eventSubmissionFee <= 0;
}

double _toDouble(dynamic value, double fallback) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}
