import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
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
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),
                        
                        // Illustration with Glow
                        const Center(
                          child: AuthIllustration(),
                        ),
                        
                        const Spacer(flex: 2),
                        
                        // Welcome Text
                        const Text(
                          'Welcome to ALUR',
                          style: TextStyle(
                            color: AppColors.charcoal,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your realistic daily planner.',
                          style: TextStyle(
                            color: AppColors.warmGray,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const Spacer(flex: 3),
                        
                        // Google Sign In Button
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.inkBlack),
                              ),
                            ),
                          )
                        else
                          GoogleSignInButton(
                            onPressed: _handleGoogleSignIn,
                            text: 'Continue with Google',
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Terms
                        const Text(
                          'By continuing, you agree to our Terms',
                          style: TextStyle(
                            color: AppColors.warmGray,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const Spacer(flex: 1),
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
