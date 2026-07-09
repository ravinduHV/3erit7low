import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double percent;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  const ProgressRing({
    Key? key,
    required this.percent,
    this.size = 60.0,
    this.strokeWidth = 6.0,
    this.color,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;
    final bg = backgroundColor ??
        (theme.brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200]);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent / 100.0,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            backgroundColor: bg,
          ),
          Text(
            "${percent.toInt()}%",
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
