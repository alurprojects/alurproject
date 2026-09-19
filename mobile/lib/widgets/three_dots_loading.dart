import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ThreeDotsLoading extends StatefulWidget {
  final Color dotColor;
  final double dotSize;
  final double spacing;
  final double height;

  const ThreeDotsLoading({
    super.key,
    this.dotColor = AppColors.warmGray,
    this.dotSize = 8.0,
    this.spacing = 6.0,
    this.height = 50.0,
  });

  @override
  State<ThreeDotsLoading> createState() => _ThreeDotsLoadingState();
}

class _ThreeDotsLoadingState extends State<ThreeDotsLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final progress = (_controller.value - delay) % 1.0;
                final wave = math.sin(progress * 2 * math.pi);
                final bounce = wave > 0 ? wave : 0.0;
                final translateY = -5.0 * bounce;
                final opacity = 0.35 + (0.65 * bounce);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                  child: Transform.translate(
                    offset: Offset(0, translateY),
                    child: Opacity(
                      opacity: opacity.clamp(0.2, 1.0),
                      child: Container(
                        width: widget.dotSize,
                        height: widget.dotSize,
                        decoration: BoxDecoration(
                          color: widget.dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
