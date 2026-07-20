import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../viewmodel/qibla_viewmodel.dart';

/// The compass dial: a rose that counter-rotates with the device, and a Qibla
/// needle that settles at the top when the user is facing the Kaaba.
class QiblaCompass extends StatelessWidget {
  const QiblaCompass({super.key, required this.state});

  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    final size = 260.w;
    final heading = state.heading;
    final relative = state.relativeBearing;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The rose turns opposite the device so N keeps pointing at true
          // north in the world. Without a heading it stays put rather than
          // implying the top of the screen is north.
          Transform.rotate(
            angle: heading == null ? 0 : -heading * math.pi / 180,
            child: CustomPaint(
              size: Size(size, size),
              painter: _CompassRosePainter(isLive: heading != null),
            ),
          ),
          if (relative != null)
            Transform.rotate(
              angle: relative * math.pi / 180,
              child: CustomPaint(
                size: Size(size, size),
                painter: _QiblaNeedlePainter(
                  color: state.isAligned
                      ? AppColors.success
                      : (state.hasInterference
                          ? AppColors.warning
                          : AppColors.primary),
                ),
              ),
            ),
          if (relative == null)
            Icon(Icons.explore_off_outlined,
                size: 56.sp, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _CompassRosePainter extends CustomPainter {
  const _CompassRosePainter({required this.isLive});

  /// Dimmed when there is no live heading, so a stale dial does not read as a
  /// working one.
  final bool isLive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final opacity = isLive ? 1.0 : 0.35;

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.primary.withValues(alpha: 0.25 * opacity),
    );

    final tickPaint = Paint()..strokeCap = StrokeCap.round;

    for (var degrees = 0; degrees < 360; degrees += 15) {
      final isCardinal = degrees % 90 == 0;
      final isMajor = degrees % 45 == 0;

      final angle = (degrees - 90) * math.pi / 180;
      final outer = radius - 6;
      final inner = outer - (isCardinal ? 16 : (isMajor ? 11 : 6));

      tickPaint
        ..strokeWidth = isCardinal ? 3 : 1.5
        ..color = (isCardinal ? AppColors.primary : AppColors.textSecondary)
            .withValues(alpha: (isCardinal ? 0.9 : 0.4) * opacity);

      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        tickPaint,
      );
    }

    const labels = {0: 'উ', 90: 'পূ', 180: 'দ', 270: 'প'};
    for (final entry in labels.entries) {
      final angle = (entry.key - 90) * math.pi / 180;
      final distance = radius - 36;

      final painter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: (entry.key == 0 ? AppColors.primary : AppColors.textSecondary)
                .withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        center +
            Offset(math.cos(angle) * distance, math.sin(angle) * distance) -
            Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_CompassRosePainter oldDelegate) =>
      oldDelegate.isLive != isLive;
}

class _QiblaNeedlePainter extends CustomPainter {
  const _QiblaNeedlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final tip = center + Offset(0, -(radius - 30));

    // A tapered arrowhead rather than a full needle: only one end means
    // anything, and a symmetric needle invites reading the wrong end.
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 14, tip.dy + 26)
      ..lineTo(tip.dx, tip.dy + 19)
      ..lineTo(tip.dx + 14, tip.dy + 26)
      ..close();

    canvas.drawPath(path, Paint()..color = color);

    canvas.drawLine(
      center,
      tip + const Offset(0, 22),
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_QiblaNeedlePainter oldDelegate) =>
      oldDelegate.color != color;
}
