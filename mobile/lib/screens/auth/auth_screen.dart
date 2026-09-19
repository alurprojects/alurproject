import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/three_dots_loading.dart';
import 'widgets/auth_illustration.dart';
import 'widgets/google_sign_in_button.dart';

class AuthScreen extends StatefulWidget {
  final AuthService? authService;

  const AuthScreen({super.key, this.authService});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthService _authService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login gagal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 3),

                        // Illustration with Glow
                        const Center(child: AuthIllustration(height: 480)),

                        const SizedBox(height: 28),

                        // Welcome Text
                        Text(
                          'BE KIND TO YOUR TIME.',
                          style: GoogleFonts.inter(
                            color: AppColors.charcoal,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A realistic planner that respects your limits.',
                          style: TextStyle(
                            color: AppColors.warmGray,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 28),

                        // Google Sign In Button
                        if (_isLoading)
                          const ThreeDotsLoading(
                            dotColor: AppColors.warmGray,
                            dotSize: 8,
                            spacing: 8,
                            height: 50,
                          )
                        else
                          GoogleSignInButton(
                            onPressed: _handleGoogleSignIn,
                            text: 'Continue with Google',
                          ),

                        const SizedBox(height: 16),

                        // Terms
                        const Text(
                          'By continuing, you agree to our Terms',
                          style: TextStyle(
                            color: AppColors.warmGray,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
