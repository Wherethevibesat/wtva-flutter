import 'user_role.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final UserRole role;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // For role-specific data

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.role,
    required this.createdAt,
    this.metadata,
  });

  // Helper getters for role-specific data
  String? get venueId => metadata?['venueId'] as String?;
  List<String>? get managedVenueIds => metadata?['managedVenueIds'] as List<String>?;
  bool get isAdmin => role == UserRole.admin;
  bool get isVenueOwner => role == UserRole.venueOwner;
  bool get isCustomer => role == UserRole.customer;

  // Check if user can perform an action
  bool canManageVenue(String venueId) {
    if (isAdmin) return true;
    if (isVenueOwner) {
      return venueId == this.venueId || 
             (managedVenueIds?.contains(venueId) ?? false);
    }
    return false;
  }

  bool canCreateEvent() {
    return isAdmin || isVenueOwner;
  }

  bool canApproveContent() {
    return isAdmin;
  }

  bool canFeatureContent() {
    return isAdmin;
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    UserRole? role,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

