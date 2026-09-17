import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AuthIllustration extends StatelessWidget {
  final double height;

  const AuthIllustration({super.key, this.height = 240});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle pastel glow in background
          Positioned.fill(
            child: CustomPaint(
              painter: _PastelGlowPainter(),
            ),
          ),
          // Editorial monochrome line-art figure
          CustomPaint(
            size: Size(260, height),
            painter: _CharacterLineArtPainter(),
          ),
        ],
      ),
    );
  }
}

class _PastelGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.45, size.height * 0.45);
    final rect = Rect.fromCircle(center: center, radius: size.height * 0.55);

    // Soft multi-stop pastel radial glow
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE8F5E9).withValues(alpha: 0.55), // soft mint
          const Color(0xFFE1F5FE).withValues(alpha: 0.50), // soft cyan
          const Color(0xFFEDE7F6).withValues(alpha: 0.45), // soft lavender
          const Color(0xFFFFF3E0).withValues(alpha: 0.35), // soft peach
          AppColors.warmOffWhite.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, size.height * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CharacterLineArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = AppColors.charcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinStroke = Paint()
      ..color = AppColors.charcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.warmOffWhite
      ..style = PaintingStyle.fill;

    final blackFill = Paint()
      ..color = AppColors.charcoal
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final scale = h / 240.0;

    canvas.save();
    canvas.translate((w - 200 * scale) / 2, 10 * scale);
    canvas.scale(scale);

    // 1. Chair back and seat
    final chairPath = Path()
      ..moveTo(140, 100)
      ..cubicTo(165, 105, 175, 130, 170, 165)
      ..cubicTo(168, 178, 155, 185, 135, 185)
      ..lineTo(110, 185);
    canvas.drawPath(chairPath, fillPaint);
    canvas.drawPath(chairPath, strokePaint);

    // Chair legs
    canvas.drawLine(const Offset(155, 185), const Offset(170, 225), strokePaint);
    canvas.drawLine(const Offset(130, 185), const Offset(135, 225), strokePaint);

    // 2. Footrest / Box block
    final boxRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(42, 175, 36, 45),
      const Radius.circular(4),
    );
    canvas.drawRRect(boxRect, fillPaint);
    canvas.drawRRect(boxRect, strokePaint);
    // Inner box speaker/details
    canvas.drawCircle(const Offset(60, 188), 6, strokePaint);
    canvas.drawCircle(const Offset(60, 206), 6, strokePaint);

    // 3. Legs & Pants (Stylized wide-leg trousers)
    // Left leg resting on box
    final leftLeg = Path()
      ..moveTo(98, 140)
      ..lineTo(56, 155)
      ..lineTo(60, 175)
      ..lineTo(82, 175)
      ..lineTo(105, 155)
      ..close();
    canvas.drawPath(leftLeg, fillPaint);
    canvas.drawPath(leftLeg, strokePaint);

    // Shoe on box
    final shoeOnBox = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 168, 28, 10),
      const Radius.circular(3),
    );
    canvas.drawRRect(shoeOnBox, blackFill);

    // Right leg hanging down
    final rightLeg = Path()
      ..moveTo(105, 148)
      ..lineTo(115, 152)
      ..lineTo(112, 215)
      ..lineTo(94, 215)
      ..lineTo(92, 160)
      ..close();
    canvas.drawPath(rightLeg, fillPaint);
    canvas.drawPath(rightLeg, strokePaint);

    // Shoe on floor
    final shoeFloor = Path()
      ..moveTo(94, 215)
      ..lineTo(118, 215)
      ..cubicTo(122, 215, 126, 220, 122, 225)
      ..lineTo(90, 225)
      ..close();
    canvas.drawPath(shoeFloor, blackFill);

    // 4. Torso & Jacket / Shirt
    final torso = Path()
      ..moveTo(100, 95)
      ..lineTo(142, 98)
      ..cubicTo(145, 125, 140, 145, 130, 155)
      ..lineTo(95, 150)
      ..close();
    canvas.drawPath(torso, fillPaint);
    canvas.drawPath(torso, strokePaint);

    // Collar detail
    canvas.drawLine(const Offset(116, 96), const Offset(120, 115), thinStroke);

    // 5. Head, Hair, Glasses & Profile Face
    // Head shape
    final head = Path()
      ..moveTo(112, 70)
      ..cubicTo(110, 60, 118, 48, 130, 48)
      ..cubicTo(142, 48, 148, 58, 145, 70)
      ..cubicTo(144, 76, 140, 84, 132, 88)
      ..lineTo(122, 88)
      ..close();
    canvas.drawPath(head, fillPaint);
    canvas.drawPath(head, strokePaint);

    // Hair (Solid Black)
    final hair = Path()
      ..moveTo(116, 64)
      ..cubicTo(112, 52, 122, 44, 132, 44)
      ..cubicTo(144, 44, 148, 52, 148, 62)
      ..cubicTo(148, 68, 142, 68, 140, 64)
      ..cubicTo(138, 54, 130, 52, 124, 58)
      ..close();
    canvas.drawPath(hair, blackFill);

    // Glasses
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(112, 60, 10, 8),
        const Radius.circular(2),
      ),
      strokePaint,
    );
    canvas.drawLine(const Offset(122, 64), const Offset(130, 64), strokePaint);

    // Neck
    canvas.drawLine(const Offset(122, 88), const Offset(122, 96), strokePaint);
    canvas.drawLine(const Offset(132, 88), const Offset(134, 97), strokePaint);

    // 6. Right Arm holding Smartphone
    final rightArm = Path()
      ..moveTo(134, 102)
      ..lineTo(120, 132)
      ..lineTo(102, 118)
      ..lineTo(98, 88);
    canvas.drawPath(rightArm, strokePaint);

    // Smartphone
    final phone = RRect.fromRectAndRadius(
      const Rect.fromLTWH(92, 72, 13, 24),
      const Radius.circular(3),
    );
    canvas.drawRRect(phone, blackFill);

    // Hand holding phone
    canvas.drawCircle(const Offset(100, 86), 4, fillPaint);
    canvas.drawCircle(const Offset(100, 86), 4, strokePaint);

    // 7. Left Arm resting & holding cigarette
    final leftArm = Path()
      ..moveTo(110, 106)
      ..lineTo(82, 126)
      ..lineTo(60, 132)
      ..lineTo(50, 128);
    canvas.drawPath(leftArm, strokePaint);

    // Cigarette
    canvas.drawLine(const Offset(50, 128), const Offset(40, 125), strokePaint);

    // Smoke curls (editorial delicate curls)
    final smoke = Path()
      ..moveTo(38, 124)
      ..cubicTo(32, 115, 42, 108, 36, 96)
      ..cubicTo(30, 85, 40, 75, 34, 62)
      ..cubicTo(30, 52, 38, 44, 32, 34);
    canvas.drawPath(smoke, thinStroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
