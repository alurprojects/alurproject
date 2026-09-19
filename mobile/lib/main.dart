import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Gagal memuat file .env: $e");
  }

  // Initialize Supabase if env variables are available
  if (AppEnv.supabaseUrl.isNotEmpty && AppEnv.supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        anonKey: AppEnv.supabaseAnonKey, // ignore: deprecated_member_use
      );
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
    }
  } else {
    debugPrint(
      '⚠️ PERINGATAN: AppEnv.supabaseUrl atau AppEnv.supabaseAnonKey kosong!\n'
      'Pastikan file .env ada di folder mobile dan isinya benar.',
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(AlurApp(initialDarkMode: isDarkMode));
}

class AlurApp extends StatefulWidget {
  final bool initialDarkMode;

  const AlurApp({super.key, required this.initialDarkMode});

  @override
  State<AlurApp> createState() => _AlurAppState();
}

class _AlurAppState extends State<AlurApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  void _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALUR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthGate(
        onToggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}
