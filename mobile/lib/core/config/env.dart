import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded via flutter_dotenv
/// Strictly contains only PUBLIC_* variables.
abstract final class AppEnv {
  static String get supabaseUrl => dotenv.env['PUBLIC_SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['PUBLIC_SUPABASE_ANON_KEY'] ?? '';
  static String get googleWebClientId => dotenv.env['PUBLIC_GOOGLE_WEB_CLIENT_ID'] ?? '';
}
