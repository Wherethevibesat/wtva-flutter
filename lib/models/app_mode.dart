import 'package:flutter/material.dart';

/// Which experience the user is in within the single app.
enum AppMode {
  customer,
  business;

  String get prefsKey {
    switch (this) {
      case AppMode.customer:
        return 'customer';
      case AppMode.business:
        return 'business';
    }
  }

  static AppMode? fromPrefsKey(String? key) {
    switch (key) {
      case 'customer':
        return AppMode.customer;
      case 'business':
        return AppMode.business;
      default:
        return null;
    }
  }

  String get pickerTitle {
    switch (this) {
      case AppMode.customer:
        return "I'm going out";
      case AppMode.business:
        return 'I run a venue';
    }
  }

  String get pickerSubtitle {
    switch (this) {
      case AppMode.customer:
        return 'Discover, check in, rank up';
      case AppMode.business:
        return 'Promote, book talent, analytics';
    }
  }

  IconData get pickerIcon {
    switch (this) {
      case AppMode.customer:
        return Icons.nightlife_outlined;
      case AppMode.business:
        return Icons.storefront_outlined;
    }
  }
}
