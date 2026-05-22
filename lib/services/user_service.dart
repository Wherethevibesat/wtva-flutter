import '../config/dev_auth_config.dart';
import '../models/app_mode.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'app_mode_service.dart';
import 'auth_service.dart';
import 'business_service.dart';
import 'favorites_service.dart';
import 'ranking_service.dart';

/// Service to manage current user state
/// Integrates with Supabase authentication
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _dummyAuthActive = false;
  bool _isGuestSession = false;

  bool get isDummyAuthenticated => _dummyAuthActive;
  bool get isGuest => _isGuestSession;

  // Mock users for testing different roles (fallback when not authenticated)
  static final User mockAdmin = User(
    id: 'admin-1',
    email: 'admin@wherethevibesat.com',
    name: 'Admin User',
    role: UserRole.admin,
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );

  static final User mockVenueOwner = User(
    id: 'venue-1',
    email: 'owner@postoak.com',
    name: 'Venue Owner',
    role: UserRole.venueOwner,
    createdAt: DateTime.now().subtract(const Duration(days: 180)),
    metadata: {
      'venueId': 'venue-1',
      'managedVenueIds': ['venue-1'],
    },
  );

  static final User mockCustomer = User(
    id: 'customer-1',
    email: 'customer@example.com',
    name: 'John Doe',
    role: UserRole.customer,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  /// Browse-only session — not a logged-in account.
  static final User guestBrowsingUser = User(
    id: 'guest',
    email: '',
    name: 'Guest',
    role: UserRole.customer,
    createdAt: DateTime.now(),
  );

  User? get currentUser => _currentUser;

  /// True only for a real account (Supabase or dev dummy login), not guest browse.
  bool get isLoggedIn =>
      !_isGuestSession &&
      (_authService.isAuthenticated ||
          (_dummyAuthActive && _currentUser != null));

  /// Guest or signed-in user may use the main app shell (discover, browse venues).
  bool get hasAppAccess => isLoggedIn || (_isGuestSession && _currentUser != null);

  /// Load the signed-in user from Supabase and clear guest/demo session state.
  Future<bool> syncFromAuth({String? fallbackName, String? fallbackEmail}) async {
    if (!_authService.isAuthenticated) {
      return false;
    }

    final supabaseUser = _authService.currentUser;
    if (supabaseUser == null) {
      return false;
    }

    _isGuestSession = false;
    _dummyAuthActive = false;

    var profile = await _authService.getUserProfile(supabaseUser.id);
    final resolvedName = fallbackName?.trim().isNotEmpty == true
        ? fallbackName!.trim()
        : (profile?.name ?? 'User');
    final resolvedEmail = fallbackEmail?.trim().isNotEmpty == true
        ? fallbackEmail!.trim()
        : (profile?.email ?? supabaseUser.email ?? '');

    if (profile == null) {
      await _authService.ensureUserProfile(
        userId: supabaseUser.id,
        email: resolvedEmail,
        name: resolvedName,
        role: UserRole.customer,
      );
      profile = await _authService.getUserProfile(supabaseUser.id);
    }

    profile ??= _authService.userFromAuthUser(
      supabaseUser,
      fallbackName: resolvedName,
      fallbackEmail: resolvedEmail,
    );

    _currentUser = profile;
    await _onSessionChanged();
    return true;
  }

  /// Initialize user from Supabase session (e.g. app start, auth listener).
  Future<void> initializeUser() async {
    await syncFromAuth();
  }

  /// Browse the app without an account (limited features).
  void continueAsGuest() {
    _currentUser = guestBrowsingUser;
    _dummyAuthActive = false;
    _isGuestSession = true;
    _onSessionChanged();
  }

  UserRole _roleForNewDummyUser() {
    final mode = AppModeService.instance.mode;
    if (mode == AppMode.business) return UserRole.venueOwner;
    return UserRole.customer;
  }

  /// Dummy registration — any email + password (6+ chars).
  bool registerDummy({
    required String email,
    required String password,
    required String name,
    UserRole? role,
  }) {
    if (!DevAuthConfig.useDummyAuth) return false;
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) return false;
    if (password.length < 6) return false;

    final resolvedRole = role ?? _roleForNewDummyUser();
    final user = User(
      id: 'demo-${normalizedEmail.hashCode}',
      email: normalizedEmail,
      name: name.trim().isEmpty ? normalizedEmail.split('@').first : name.trim(),
      role: resolvedRole,
      createdAt: DateTime.now(),
      metadata: resolvedRole == UserRole.venueOwner
          ? {'venueId': 'venue-1', 'managedVenueIds': ['venue-1']}
          : null,
    );
    loginAs(user, dummy: true);
    return true;
  }

  /// Dummy sign-in for local development (no Supabase).
  bool tryDummyLogin({required String email, required String password}) {
    if (!DevAuthConfig.useDummyAuth) return false;

    final normalizedEmail = email.trim().toLowerCase();
    if (password.trim() != DevAuthConfig.dummyPassword) return false;

    final roleKey = DevAuthConfig.dummyAccounts[normalizedEmail];
    if (roleKey == null) {
      return registerDummy(
        email: normalizedEmail,
        password: password,
        name: normalizedEmail.split('@').first,
      );
    }

    final mode = AppModeService.instance.mode;
    switch (roleKey) {
      case 'admin':
        if (mode == AppMode.business) return false;
        loginAs(mockAdmin, dummy: true);
        return true;
      case 'owner':
        if (mode == AppMode.customer) return false;
        loginAs(mockVenueOwner, dummy: true);
        return true;
      case 'customer':
        if (mode == AppMode.business) return false;
        loginAs(mockCustomer, dummy: true);
        return true;
      default:
        return false;
    }
  }

  bool get isBusinessSession =>
      AppModeService.instance.mode == AppMode.business &&
      (_currentUser?.isVenueOwner ?? false);

  bool get isCustomerSession =>
      AppModeService.instance.mode == AppMode.customer &&
      (_currentUser?.role == UserRole.customer);

  /// Set current user (used after login)
  void setUser(User user) {
    _currentUser = user;
    _onSessionChanged();
  }

  Future<void> _onSessionChanged() async {
    await RankingService.instance.onUserChanged();
    await FavoritesService.instance.onUserChanged();
    await BusinessService.instance.onAuthChanged();
  }

  /// Clear current user (used after logout)
  void clearUser() {
    _currentUser = null;
    _dummyAuthActive = false;
    _isGuestSession = false;
    _onSessionChanged();
  }

  // Initialize with a default user (for demo purposes - deprecated, use initializeUser)
  @Deprecated('Use initializeUser() instead')
  void initializeWithDefaultUser() {
    if (_currentUser == null) {
      loginAs(mockCustomer, dummy: DevAuthConfig.useDummyAuth);
    }
  }

  // Login with a specific user (for demo/testing)
  void loginAs(User user, {bool dummy = false}) {
    _currentUser = user;
    _dummyAuthActive = dummy;
    _isGuestSession = false;
    _onSessionChanged();
  }

  // Login with a role (for demo/testing)
  // SECURITY: This should only be used in development/testing environments
  // In production, roles should be managed through the backend/database
  @Deprecated('Role switching should be managed server-side. This is for development only.')
  void loginAsRole(UserRole role) {
    // Only allow role switching if current user is admin (for testing purposes)
    // In production, this should be completely disabled
    if (_currentUser?.isAdmin != true) {
      throw Exception('Only admins can switch roles. This feature is for development/testing only.');
    }
    
    switch (role) {
      case UserRole.admin:
        _currentUser = mockAdmin;
        break;
      case UserRole.venueOwner:
        _currentUser = mockVenueOwner;
        break;
      case UserRole.customer:
        _currentUser = mockCustomer;
        break;
    }
  }

  void logout() {
    clearUser();
  }

  /// Updates display name for the current session (demo / local).
  void updateDisplayName(String name) {
    final user = _currentUser;
    if (user == null || name.trim().isEmpty) return;
    _currentUser = user.copyWith(name: name.trim());
  }

  // Check permissions
  bool canSubmitContent() {
    return _currentUser?.isVenueOwner ?? false;
  }

  bool canApproveContent() {
    return _currentUser?.isAdmin ?? false;
  }

  bool canManageVenue(String venueId) {
    return _currentUser?.canManageVenue(venueId) ?? false;
  }

  bool get isAdmin {
    return _currentUser?.isAdmin ?? false;
  }
}

