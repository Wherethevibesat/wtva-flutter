import '../models/business/business_models.dart';

/// Demo metrics and lists for the business shell.
class MockBusinessData {
  MockBusinessData._();

  static const venueName = 'Post Oak Bar';
  static const planLabel = 'Gold · demo';

  static const dashboardStats = [
    ('Check-ins today', '42'),
    ('Visitors this week', '318'),
    ('Active promotions', '2'),
    ('Pending bookings', '3'),
  ];

  static const adMetrics = ('1,223', '3,422', '42');

  static const talentProfiles = [
    BusinessTalentProfile(
      id: 't1',
      name: 'Alex Rivera',
      tier: 'Vibe Champion',
      points: 28400,
      city: 'Houston',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
      age: 28,
      gender: 'Male',
    ),
    BusinessTalentProfile(
      id: 't2',
      name: 'Jordan Lee',
      tier: 'Vibe Master',
      points: 12400,
      city: 'Austin',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
      age: 26,
      gender: 'Non-binary',
    ),
    BusinessTalentProfile(
      id: 't3',
      name: 'Sam Taylor',
      tier: 'Vibee',
      points: 620,
      city: 'Dallas',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&q=80',
      age: 23,
      gender: 'Female',
    ),
    BusinessTalentProfile(
      id: 't4',
      name: 'Morgan Kim',
      tier: 'Vibesetter',
      points: 51200,
      city: 'Houston',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
      age: 31,
      gender: 'Female',
    ),
  ];

  static const checkIns = [
    BusinessCheckInRecord(
      id: 'c1',
      guestName: 'Morgan Kim',
      timeAgo: '12 min ago',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&q=80',
    ),
    BusinessCheckInRecord(
      id: 'c2',
      guestName: 'Alex Rivera',
      timeAgo: '34 min ago',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&q=80',
    ),
    BusinessCheckInRecord(
      id: 'c3',
      guestName: 'Sam Taylor',
      timeAgo: '1 hr ago',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&q=80',
    ),
  ];

  static const companiesNearby = [
    ('The Rustic', 'Bar · 0.8 mi'),
    ('Cle Houston', 'Night club · 1.2 mi'),
    ('Barbarella', 'Live music · 2.1 mi'),
  ];

  static List<BusinessBooking> initialBookings() => [
        BusinessBooking(
          id: 'bk1',
          talentId: 't1',
          talentName: 'Alex Rivera',
          status: BusinessBookingStatus.confirmed,
          eventAt: DateTime.now().add(const Duration(days: 2)),
        ),
        BusinessBooking(
          id: 'bk2',
          talentId: 't2',
          talentName: 'Jordan Lee',
          status: BusinessBookingStatus.pending,
          eventAt: DateTime.now().add(const Duration(days: 1)),
        ),
        BusinessBooking(
          id: 'bk3',
          talentId: 't4',
          talentName: 'Morgan Kim',
          status: BusinessBookingStatus.checkedIn,
          eventAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

  static List<BusinessPromotion> initialPromotions() => [
        const BusinessPromotion(
          id: 'p1',
          title: 'Friday VIP tables',
          status: 'Live',
          detail: '1.2k impressions',
          description: '50% off entry before 11 PM',
        ),
        const BusinessPromotion(
          id: 'p2',
          title: 'Ladies night feature',
          status: 'Scheduled',
          detail: 'Starts Fri 9pm',
          description: 'Featured on Discover',
        ),
      ];

  static const subscriptionPerks = {
    BusinessSubscriptionTier.silver: ['Business profile', 'Basic analytics', '1 promotion / mo'],
    BusinessSubscriptionTier.gold: ['Browse ranked users', 'Book invites', 'Featured promos'],
    BusinessSubscriptionTier.platinum: ['Priority support', 'Live stream slot', 'Unlimited promos'],
  };

  static const banks = ['Chase', 'Bank of America', 'Wells Fargo', 'Capital One'];
}

/// @deprecated Use [BusinessTalentProfile].
typedef BusinessTalentUser = BusinessTalentProfile;
