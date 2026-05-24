/// Business-side domain models (demo / local).
library;

import 'venue_opening_hours.dart';

export 'venue_opening_hours.dart';
enum BusinessBookingStatus {
  pending,
  confirmed,
  checkedIn,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case BusinessBookingStatus.pending:
        return 'Pending';
      case BusinessBookingStatus.confirmed:
        return 'Confirmed';
      case BusinessBookingStatus.checkedIn:
        return 'Checked in';
      case BusinessBookingStatus.completed:
        return 'Completed';
      case BusinessBookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum BusinessSubscriptionTier {
  silver,
  gold,
  platinum;

  String get label {
    switch (this) {
      case BusinessSubscriptionTier.silver:
        return 'Silver';
      case BusinessSubscriptionTier.gold:
        return 'Gold';
      case BusinessSubscriptionTier.platinum:
        return 'Platinum';
    }
  }

  String get priceLabel {
    switch (this) {
      case BusinessSubscriptionTier.silver:
        return '\$49/mo';
      case BusinessSubscriptionTier.gold:
        return '\$99/mo';
      case BusinessSubscriptionTier.platinum:
        return '\$199/mo';
    }
  }
}

class BusinessTalentProfile {
  final String id;
  final String name;
  final String tier;
  final int points;
  final String city;
  final String? avatarUrl;
  final int age;
  final String gender;
  final String bio;

  const BusinessTalentProfile({
    required this.id,
    required this.name,
    required this.tier,
    required this.points,
    required this.city,
    this.avatarUrl,
    this.age = 25,
    this.gender = 'Any',
    this.bio = 'Nightlife regular · open to paid venue invites.',
  });
}

class BusinessBooking {
  final String id;
  final String talentId;
  final String talentName;
  final BusinessBookingStatus status;
  final DateTime eventAt;
  final double amount;
  final String note;

  const BusinessBooking({
    required this.id,
    required this.talentId,
    required this.talentName,
    required this.status,
    required this.eventAt,
    this.amount = 150,
    this.note = 'VIP table invite',
  });

  BusinessBooking copyWith({BusinessBookingStatus? status}) {
    return BusinessBooking(
      id: id,
      talentId: talentId,
      talentName: talentName,
      status: status ?? this.status,
      eventAt: eventAt,
      amount: amount,
      note: note,
    );
  }
}

class BusinessPromotion {
  final String id;
  final String title;
  final String status;
  final String detail;
  final String description;

  const BusinessPromotion({
    required this.id,
    required this.title,
    required this.status,
    required this.detail,
    this.description = '',
  });
}

class BusinessBrowseFilters {
  String sortBy;
  String datePosted;
  String location;
  String ageRange;
  String gender;

  BusinessBrowseFilters({
    this.sortBy = 'Highest rank',
    this.datePosted = 'Any time',
    this.location = 'Houston',
    this.ageRange = '21–35',
    this.gender = 'Any',
  });

  BusinessBrowseFilters copy() => BusinessBrowseFilters(
        sortBy: sortBy,
        datePosted: datePosted,
        location: location,
        ageRange: ageRange,
        gender: gender,
      );
}

class BusinessVenueProfile {
  String venueName;
  String venueType;
  String address;
  String neighborhood;
  String phone;
  String description;
  String? imageUrl;
  VenueOpeningHours openingHours;
  String websiteUrl;
  String instagramUrl;
  String facebookUrl;
  String tiktokUrl;
  String twitterUrl;
  List<String> categories;
  List<String> serviceOptions;
  BusinessSubscriptionTier tier;
  bool verified;
  String? verificationDocumentPath;
  String verificationStatus;

  BusinessVenueProfile({
    this.venueName = 'My Venue',
    this.venueType = 'Nightclub',
    this.address = '',
    this.neighborhood = '',
    this.phone = '',
    this.description = '',
    this.imageUrl,
    VenueOpeningHours? openingHours,
    this.websiteUrl = '',
    this.instagramUrl = '',
    this.facebookUrl = '',
    this.tiktokUrl = '',
    this.twitterUrl = '',
    this.categories = const ['Bars', 'Night clubs'],
    this.serviceOptions = const ['VIP tables', 'Bottle service'],
    this.tier = BusinessSubscriptionTier.gold,
    this.verified = false,
    this.verificationDocumentPath,
    this.verificationStatus = 'none',
  }) : openingHours = openingHours ?? VenueOpeningHours.defaults();
}

class BusinessCheckInRecord {
  final String id;
  final String guestName;
  final String timeAgo;
  final String? avatarUrl;

  const BusinessCheckInRecord({
    required this.id,
    required this.guestName,
    required this.timeAgo,
    this.avatarUrl,
  });
}
