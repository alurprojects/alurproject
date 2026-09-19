import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/config/env.dart';

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
      throw Exception(
        'Supabase belum diinisialisasi. Pastikan file .env sudah dikonfigurasi.',
      );
    }
    
    try {
      if (kIsWeb) {
        return await client.auth.signInWithOAuth(
          OAuthProvider.google,
          authScreenLaunchMode: LaunchMode.platformDefault,
        );
      } else {
        // Native Google Sign-In
        final webClientId = AppEnv.googleWebClientId;
        if (webClientId.isEmpty) {
          throw Exception('PUBLIC_GOOGLE_WEB_CLIENT_ID belum dikonfigurasi di file .env');
        }
        
        final googleSignIn = GoogleSignIn(serverClientId: webClientId);
        final googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          // User membatalkan login
          return false;
        }
        
        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;
        
        if (accessToken == null || idToken == null) {
          throw Exception('Gagal mendapatkan token autentikasi Google.');
        }
        
        final response = await client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
        
        return response.user != null;
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _client?.auth.signOut();
  }
}
