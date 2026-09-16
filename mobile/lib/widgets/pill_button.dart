import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Reusable fully rounded pill button matching ALUR high-contrast design
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;
  final bool isLoading;
  final double? width;
  final double height;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isLoading = false,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSecondary
        ? Colors.transparent
        : (isDark ? AppColors.pureWhite : AppColors.pureBlack);

    final fgColor = isSecondary
        ? (isDark ? AppColors.pureWhite : AppColors.pureBlack)
        : (isDark ? AppColors.pureBlack : AppColors.pureWhite);

    final borderColor = isDark ? AppColors.pureWhite : AppColors.pureBlack;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: isSecondary ? Colors.transparent : Colors.grey.shade400,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height / 2),
            side: isSecondary ? BorderSide(color: borderColor, width: 1.5) : BorderSide.none,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18, color: fgColor),
                  ],
                ],
              ),
      ),
    );
  }
}
