/// Collected fields across the registration wizard.
class RegistrationData {
  String email = '';
  String name = '';
  String password = '';
  bool rememberSignIn = true;
  bool acceptedTerms = false;
  bool locationEnabled = false;
  bool notificationsEnabled = false;
  String? username;

  List<String> get favoriteCategories => List.unmodifiable(_categories);
  final List<String> _categories = [];

  void toggleCategory(String c) {
    if (_categories.contains(c)) {
      _categories.remove(c);
    } else {
      _categories.add(c);
    }
  }
}
