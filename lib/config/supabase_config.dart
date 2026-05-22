/// Supabase Configuration
/// 
/// IMPORTANT: Replace these with your actual Supabase project credentials
/// You can find these in your Supabase project settings:
/// https://app.supabase.com/project/_/settings/api
class SupabaseConfig {
  static const String supabaseUrl = 'https://wabtknktqnrxnffkgpzh.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhYnRrbmt0cW5yeG5mZmtncHpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk0MDcyMDMsImV4cCI6MjA5NDk4MzIwM30.lbDi-RJz09k3kuRAd1obvwAEuhce89f2N7Bl1dsIoLU';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('YOUR_SUPABASE') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('YOUR_SUPABASE');
  
  // Optional: Add service role key for admin operations (server-side only)
  // static const String supabaseServiceRoleKey = 'YOUR_SERVICE_ROLE_KEY';
}

