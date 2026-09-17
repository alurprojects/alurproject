import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient? _customClient;

  AuthService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient? get _client {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _client?.auth.currentUser;
  Session? get currentSession => _client?.auth.currentSession;
  Stream<AuthState>? get onAuthStateChange => _client?.auth.onAuthStateChange;

  Future<bool> signInWithGoogle() async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not initialized.');
    }
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.alur://login-callback/',
      );
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }
}
