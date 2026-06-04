import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class VisionLogo extends StatelessWidget {
  final double size;

  const VisionLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VisionLogoPainter(),
      ),
    );
  }
}

class _VisionLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2 + (h * 0.05); // Offset slightly downwards to make room for buildings
    
    // Center point (cx, cy)
    final center = Offset(cx, cy);
    final eyeWidth = w * 0.8;
    final eyeHeight = h * 0.45;
    
    // 1. Draw Buildings above the eye
    final Paint buildingPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0xFF334155),
          Color(0xFF94A3B8),
          Color(0xFFF8FAFC),
        ],
      ).createShader(Rect.fromLTWH(cx - w * 0.3, cy - eyeHeight * 1.5, w * 0.6, eyeHeight * 1.5))
      ..style = PaintingStyle.fill;

    // Draw skyscrapers
    final double bWidth = w * 0.05;
    final double startY = cy - eyeHeight * 0.4;
    
    // Center tallest building
    final Path centerBuilding = Path();
    centerBuilding.moveTo(cx - bWidth * 0.7, startY);
    centerBuilding.lineTo(cx - bWidth * 0.7, cy - h * 0.42);
    centerBuilding.lineTo(cx, cy - h * 0.48); // Spire top
    centerBuilding.lineTo(cx + bWidth * 0.7, cy - h * 0.42);
    centerBuilding.lineTo(cx + bWidth * 0.7, startY);
    centerBuilding.close();
    canvas.drawPath(centerBuilding, buildingPaint);

    // Spire needle
    final Paint needlePaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy - h * 0.48), Offset(cx, cy - h * 0.52), needlePaint);

    // Left and Right Building 1
    canvas.drawRect(Rect.fromLTRB(cx - bWidth * 2.0, cy - h * 0.38, cx - bWidth * 0.9, startY), buildingPaint);
    canvas.drawRect(Rect.fromLTRB(cx + bWidth * 0.9, cy - h * 0.38, cx + bWidth * 2.0, startY), buildingPaint);
    
    // Left and Right Building 2
    canvas.drawRect(Rect.fromLTRB(cx - bWidth * 3.2, cy - h * 0.33, cx - bWidth * 2.1, startY), buildingPaint);
    canvas.drawRect(Rect.fromLTRB(cx + bWidth * 2.1, cy - h * 0.33, cx + bWidth * 3.2, startY), buildingPaint);

    // Left and Right Building 3
    canvas.drawRect(Rect.fromLTRB(cx - bWidth * 4.4, cy - h * 0.28, cx - bWidth * 3.3, startY), buildingPaint);
    canvas.drawRect(Rect.fromLTRB(cx + bWidth * 3.3, cy - h * 0.28, cx + bWidth * 4.4, startY), buildingPaint);

    // 2. Draw Dotted Arch between gems
    final Paint arcPaint = Paint()
      ..color = const Color(0xFF94A3B8).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final Path arcPath = Path();
    arcPath.addArc(
      Rect.fromCircle(center: center, radius: w * 0.42),
      -math.pi * 0.85,
      math.pi * 0.7,
    );
    
    // Custom dash drawing
    final double dashWidth = 3.0;
    final double dashSpace = 4.0;
    double distance = 0.0;
    for (PathMetric measurePath in arcPath.computeMetrics()) {
      while (distance < measurePath.length) {
        final Path extract = measurePath.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extract, arcPaint);
        distance += dashWidth + dashSpace;
      }
    }

    // 3. Draw Side Gems
    final double gemSize = w * 0.06;
    final double gemY = cy - h * 0.28;
    final double gemXOffset = w * 0.38;

    // Left Blue Gem
    final Paint leftGemPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
      ).createShader(Rect.fromCircle(center: Offset(cx - gemXOffset, gemY), radius: gemSize))
      ..style = PaintingStyle.fill;
    
    final Path leftGemPath = _createDiamondPath(cx - gemXOffset, gemY, gemSize);
    canvas.drawPath(leftGemPath, leftGemPaint);
    
    // Left Gem Glow
    final Paint leftGlowPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx - gemXOffset, gemY), gemSize * 1.2, leftGlowPaint);

    // Right Purple Gem
    final Paint rightGemPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFC084FC), Color(0xFF7E22CE), Color(0xFF581C87)],
      ).createShader(Rect.fromCircle(center: Offset(cx + gemXOffset, gemY), radius: gemSize))
      ..style = PaintingStyle.fill;
    
    final Path rightGemPath = _createDiamondPath(cx + gemXOffset, gemY, gemSize);
    canvas.drawPath(rightGemPath, rightGemPaint);

    // Right Gem Glow
    final Paint rightGlowPaint = Paint()
      ..color = const Color(0xFFA855F7).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx + gemXOffset, gemY), gemSize * 1.2, rightGlowPaint);

    // 4. Draw outer metallic eye wings/borders
    final Paint eyeBorderPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF64748B),
          Color(0xFFE2E8F0),
          Color(0xFF475569),
          Color(0xFFCBD5E1),
          Color(0xFF1E293B),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: eyeWidth / 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    // Top Eye Lid
    final Path topLid = Path();
    topLid.moveTo(cx - eyeWidth / 2, cy);
    topLid.quadraticBezierTo(cx, cy - eyeHeight * 0.8, cx + eyeWidth / 2, cy);
    canvas.drawPath(topLid, eyeBorderPaint);

    // Bottom Eye Lid
    final Path bottomLid = Path();
    bottomLid.moveTo(cx - eyeWidth / 2, cy);
    bottomLid.quadraticBezierTo(cx, cy + eyeHeight * 0.8, cx + eyeWidth / 2, cy);
    canvas.drawPath(bottomLid, eyeBorderPaint);

    // Secondary wings (under/around eye for metallic look)
    final Paint wingPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF475569), Color(0xFFCBD5E1), Color(0xFF334155)],
      ).createShader(Rect.fromCircle(center: center, radius: eyeWidth / 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Path topWing = Path();
    topWing.moveTo(cx - eyeWidth * 0.45, cy - eyeHeight * 0.1);
    topWing.quadraticBezierTo(cx, cy - eyeHeight * 0.95, cx + eyeWidth * 0.45, cy - eyeHeight * 0.1);
    canvas.drawPath(topWing, wingPaint);

    final Path bottomWing = Path();
    bottomWing.moveTo(cx - eyeWidth * 0.45, cy + eyeHeight * 0.1);
    bottomWing.quadraticBezierTo(cx, cy + eyeHeight * 0.95, cx + eyeWidth * 0.45, cy + eyeHeight * 0.1);
    canvas.drawPath(bottomWing, wingPaint);

    // 5. Draw Iris (Glowing Blue Circle)
    final double irisRadius = eyeHeight * 0.42;
    
    // Iris ambient glow
    final Paint irisGlow = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, irisRadius * 1.1, irisGlow);

    // Iris color gradient
    final Paint irisPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF38BDF8), // Cyan center
          Color(0xFF0284C7), // Blue
          Color(0xFF0369A1),
          Color(0xFF0F172A), // Dark borders
        ],
        stops: [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: irisRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, irisRadius, irisPaint);

    // Iris texture lines
    final Paint texturePaint = Paint()
      ..color = const Color(0xFFE0F2FE).withOpacity(0.15)
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < 360; i += 15) {
      final double angle = i * math.pi / 180;
      final Offset outerPoint = Offset(
        cx + math.cos(angle) * irisRadius,
        cy + math.sin(angle) * irisRadius,
      );
      final Offset innerPoint = Offset(
        cx + math.cos(angle) * (irisRadius * 0.6),
        cy + math.sin(angle) * (irisRadius * 0.6),
      );
      canvas.drawLine(innerPoint, outerPoint, texturePaint);
    }

    // 6. Draw Pupil (Dark Center Circle)
    final double pupilRadius = irisRadius * 0.55;
    final Paint pupilPaint = Paint()
      ..color = const Color(0xFF090D16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pupilRadius, pupilPaint);

    // 7. Draw City Silhouette inside Pupil
    final Paint cityPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;

    // Small black building silhouettes inside the pupil
    final double cpw = pupilRadius * 0.22;
    // Center tall tower
    canvas.drawRect(Rect.fromLTRB(cx - cpw * 0.5, cy - pupilRadius * 0.65, cx + cpw * 0.5, cy + pupilRadius), cityPaint);
    // Center spire top
    final Path spire = Path();
    spire.moveTo(cx - cpw * 0.5, cy - pupilRadius * 0.65);
    spire.lineTo(cx, cy - pupilRadius * 0.95);
    spire.lineTo(cx + cpw * 0.5, cy - pupilRadius * 0.65);
    spire.close();
    canvas.drawPath(spire, cityPaint);

    // Left and Right towers in pupil
    canvas.drawRect(Rect.fromLTRB(cx - cpw * 1.6, cy - pupilRadius * 0.45, cx - cpw * 0.7, cy + pupilRadius), cityPaint);
    canvas.drawRect(Rect.fromLTRB(cx + cpw * 0.7, cy - pupilRadius * 0.45, cx + cpw * 1.6, cy + pupilRadius), cityPaint);
    
    // Far left and right smaller towers in pupil
    canvas.drawRect(Rect.fromLTRB(cx - cpw * 2.8, cy - pupilRadius * 0.25, cx - cpw * 1.8, cy + pupilRadius), cityPaint);
    canvas.drawRect(Rect.fromLTRB(cx + cpw * 1.8, cy - pupilRadius * 0.25, cx + cpw * 2.8, cy + pupilRadius), cityPaint);

    // 8. Metallic light reflection on eye top-right
    final Paint reflectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(cx + irisRadius * 0.2, cy - irisRadius * 0.5, irisRadius * 0.35, irisRadius * 0.18),
      reflectionPaint,
    );
  }

  Path _createDiamondPath(double x, double y, double size) {
    final Path path = Path();
    path.moveTo(x, y - size); // Top
    path.lineTo(x + size, y); // Right
    path.lineTo(x, y + size); // Bottom
    path.lineTo(x - size, y); // Left
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
