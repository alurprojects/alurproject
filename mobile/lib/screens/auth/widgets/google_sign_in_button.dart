import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class GoogleSignInButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.text = 'Sign up with Google',
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.warmOffWhite,
          side: const BorderSide(color: AppColors.hairlineGray, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.charcoal),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(20, 20),
                    painter: _GoogleIconPainter(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Google 'G' brand colors
    final bluePaint = Paint()..color = const Color(0xFF4285F4);

    // Blue horizontal bar
    final barRect = Rect.fromLTRB(w * 0.45, h * 0.38, w * 0.98, h * 0.62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(1.5)),
      bluePaint,
    );

    // Outer arc strokes
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.butt;

    final arcRect = Rect.fromCircle(center: center, radius: radius * 0.78);

    // Blue arc (top-right to right)
    strokePaint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.7, 1.4, false, strokePaint);

    // Green arc (bottom-right to bottom)
    strokePaint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.7, 1.5, false, strokePaint);

    // Yellow arc (bottom-left to left)
    strokePaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.2, 1.3, false, strokePaint);

    // Red arc (left to top)
    strokePaint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, 3.5, 1.4, false, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
