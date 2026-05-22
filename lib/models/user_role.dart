import 'package:flutter/material.dart';

enum UserRole {
  admin,
  venueOwner,
  customer;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.venueOwner:
        return 'Venue Owner / Promoter';
      case UserRole.customer:
        return 'Customer';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Manage venues, events, and promoters. Approve content and feature clubs/events.';
      case UserRole.venueOwner:
        return 'Create and manage your venues, create events, and manage VIP/sections info.';
      case UserRole.customer:
        return 'Browse events & venues, follow clubs/promoters/events, receive notifications, and buy passes/request VIP.';
    }
  }

  List<String> get permissions {
    switch (this) {
      case UserRole.admin:
        return [
          'Manage all venues',
          'Manage all events',
          'Manage promoters',
          'Approve content submissions',
          'Feature clubs/events',
          'View analytics',
          'Manage user accounts',
        ];
      case UserRole.venueOwner:
        return [
          'Create and manage own venues',
          'Create events',
          'Manage VIP/sections info',
          'View own venue analytics',
          'Respond to VIP requests',
        ];
      case UserRole.customer:
        return [
          'Browse events & venues',
          'Follow clubs, promoters, events',
          'Receive notifications',
          'Buy passes',
          'Request VIP',
          'Save favorites',
        ];
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.venueOwner:
        return Icons.business;
      case UserRole.customer:
        return Icons.person;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.admin:
        return const Color(0xFFEF4444); // Red
      case UserRole.venueOwner:
        return const Color(0xFF8B5CF6); // Purple
      case UserRole.customer:
        return const Color(0xFF06B6D4); // Cyan
    }
  }
}

