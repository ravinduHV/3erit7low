import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.all(16.0),
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultColor = color ??
        (isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.4));
            
    final defaultBorderColor = borderColor ??
        (isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.3));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: defaultColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: defaultBorderColor,
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
