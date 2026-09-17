import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/api_service.dart';
import '../weekly_view/weekly_screen.dart';
import 'auth_screen.dart';

class AuthGate extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const AuthGate({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  void _checkInitialSession() {
    try {
      final client = Supabase.instance.client;
      _session = client.auth.currentSession;
      _authSubscription = client.auth.onAuthStateChange.listen((data) {
        if (mounted) {
          setState(() {
            _session = data.session;
          });
        }
      });
    } catch (_) {
      // Supabase may not be initialized (e.g. in certain test environments)
      _session = null;
    } finally {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_session != null) {
      final apiService = ApiService(authToken: _session?.accessToken);
      return WeeklyScreen(
        apiService: apiService,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      );
    }

    return const AuthScreen();
  }
}
