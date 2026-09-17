/// Environment configuration loaded via --dart-define-from-file=../.env.client
/// Strictly contains only PUBLIC_* variables.
abstract final class AppEnv {
  static const String supabaseUrl = String.fromEnvironment(
    'PUBLIC_SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'PUBLIC_SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}
