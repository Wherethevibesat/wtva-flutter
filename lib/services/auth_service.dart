import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/dev_auth_config.dart';
import '../models/user.dart' as app_models;
import '../models/user_role.dart';
import 'supabase_bootstrap.dart';

/// Authentication service using Supabase
class AuthService {
  SupabaseClient? get _supabase =>
      DevAuthConfig.useDummyAuth ? null : SupabaseBootstrap.client;

  SupabaseClient get _client {
    final client = _supabase;
    if (client == null) {
      throw StateError('Supabase auth is disabled (USE_DUMMY_AUTH=true)');
    }
    return client;
  }

  // Get current session
  Session? get currentSession => _supabase?.auth.currentSession;
  
  // Get current user (Supabase User, not our app User model)
  // Note: Supabase's currentUser returns User from gotrue, not AuthUser
  User? get currentUser => _supabase?.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated =>
      !DevAuthConfig.useDummyAuth && currentSession != null;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges =>
      _supabase?.auth.onAuthStateChange ?? const Stream.empty();

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    UserRole? role, // Optional role assignment (defaults to Customer)
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role?.name ?? UserRole.customer.name,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      // If signup successful and user is created, set up user profile
      if (response.user != null) {
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          name: name,
          role: role ?? UserRole.customer,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (DevAuthConfig.useDummyAuth) {
      throw StateError('Supabase sign-in disabled in dummy auth mode');
    }
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with OAuth provider (Google, Apple, etc.)
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      await _client.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterquickstart://reset-password/',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile from database
  Future<app_models.User?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return app_models.User(
        id: response['id'] as String,
        email: response['email'] as String? ?? '',
        name: response['name'] as String? ?? 'User',
        profileImageUrl: response['profile_image_url'] as String?,
        role: UserRole.values.firstWhere(
          (r) => r.name == (response['role'] as String? ?? 'customer'),
          orElse: () => UserRole.customer,
        ),
        createdAt: response['created_at'] != null
            ? DateTime.parse(response['created_at'] as String)
            : DateTime.now(),
        metadata: response['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? profileImageUrl,
    UserRole? role,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;
      if (role != null) updates['role'] = role.name;
      if (metadata != null) updates['metadata'] = metadata;

      await _client
          .from('users')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Create or update user profile in database (idempotent).
  Future<void> ensureUserProfile({
    required String userId,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    try {
      await _client.from('users').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'role': role.name,
        'created_at': DateTime.now().toIso8601String(),
        'metadata': {},
      }, onConflict: 'id');
    } catch (e) {
      print('Error ensuring user profile: $e');
    }
  }

  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    await ensureUserProfile(
      userId: userId,
      email: email,
      name: name,
      role: role,
    );
  }

  /// Build app user from Supabase auth when DB row is missing or slow to appear.
  app_models.User userFromAuthUser(
    User supabaseUser, {
    String? fallbackName,
    String? fallbackEmail,
  }) {
    final meta = supabaseUser.userMetadata ?? {};
    final roleName = meta['role'] as String? ?? UserRole.customer.name;
    final createdAt =
        DateTime.tryParse(supabaseUser.createdAt) ?? DateTime.now();

    return app_models.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? fallbackEmail ?? '',
      name: (meta['name'] as String?)?.trim().isNotEmpty == true
          ? meta['name'] as String
          : (fallbackName?.trim().isNotEmpty == true
              ? fallbackName!.trim()
              : (supabaseUser.email?.split('@').first ?? 'User')),
      profileImageUrl: meta['profile_image_url'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => UserRole.customer,
      ),
      createdAt: createdAt,
      metadata: meta['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final userId = currentUser?.id;
      if (userId != null) {
        // Delete user profile
        await _client.from('users').delete().eq('id', userId);
      }
      // Sign out (this will also trigger account deletion if configured)
      await signOut();
    } catch (e) {
      rethrow;
    }
  }
}

/// Helper to convert Supabase User (from gotrue) to app User model
app_models.User? convertSupabaseUserToAppUser(
  User? supabaseUser,
  Map<String, dynamic>? profileData,
) {
  if (supabaseUser == null) return null;

  // Parse createdAt - it might be a String or DateTime
  DateTime createdAt;
  if (supabaseUser.createdAt is String) {
    createdAt = DateTime.parse(supabaseUser.createdAt as String);
  } else {
    createdAt = supabaseUser.createdAt as DateTime;
  }

  return app_models.User(
    id: supabaseUser.id,
    email: supabaseUser.email ?? '',
    name: profileData?['name'] as String? ?? 'User',
    profileImageUrl: profileData?['profile_image_url'] as String?,
    role: UserRole.values.firstWhere(
      (r) => r.name == (profileData?['role'] as String? ?? 'customer'),
      orElse: () => UserRole.customer,
    ),
    createdAt: createdAt,
    metadata: profileData?['metadata'] as Map<String, dynamic>?,
  );
}

