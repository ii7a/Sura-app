import 'dart:math';
import 'package:flutter/material.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';

class CircularGauge extends StatelessWidget {
  const CircularGauge({
    super.key,
    required this.value,
    required this.maxValue,
    this.size = 120,
    this.strokeWidth = 10,
    this.backgroundColor = const Color(0xFF2E3340),
    this.label,
    this.sublabel,
    this.valueColor,
    this.centerWidget,
  });

  final double value;
  final double maxValue;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final String? label;
  final String? sublabel;
  final Color? valueColor;
  final Widget? centerWidget;

  Color get _defaultColor {
    final ratio = value / maxValue;
    if (ratio >= 0.8) return const Color(0xFF34D399);
    if (ratio >= 0.6) return const Color(0xFF8BC34A);
    if (ratio >= 0.4) return const Color(0xFFFBBF24);
    if (ratio >= 0.2) return const Color(0xFFFF9800);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? _defaultColor;
    final font = AppFonts.style(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              value: value,
              maxValue: maxValue,
              strokeWidth: strokeWidth,
              backgroundColor: backgroundColor,
              valueColor: color,
            ),
          ),
          if (centerWidget != null)
            centerWidget!
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${value.round()}',
                  style: font(
                    color: color,
                    fontSize: size * 0.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (label != null)
                  Text(
                    label!,
                    style: font(
                      color: Colors.white70,
                      fontSize: size * 0.09,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: font(
                      color: Colors.white38,
                      fontSize: size * 0.07,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.maxValue,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.valueColor,
  });

  final double value;
  final double maxValue;
  final double strokeWidth;
  final Color backgroundColor;
  final Color valueColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -pi / 2;
    const totalAngle = 2 * pi * 0.75; // 270 degrees
    final sweepAngle = totalAngle * (value / maxValue).clamp(0.0, 1.0);

    // Rotate so the gap is at the bottom
    const gapRotation = pi * 0.75;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + gapRotation,
      totalAngle,
      false,
      bgPaint,
    );

    // Value arc
    if (value > 0) {
      final valuePaint = Paint()
        ..color = valueColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gapRotation,
        sweepAngle,
        false,
        valuePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      value != oldDelegate.value ||
      maxValue != oldDelegate.maxValue ||
      valueColor != oldDelegate.valueColor;
}
