import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'screens/weekly_view/weekly_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
    _apiService = ApiService();
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
      home: WeeklyScreen(
        apiService: _apiService,
        onToggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}
