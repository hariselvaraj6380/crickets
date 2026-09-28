import 'dart:math' as math;
import 'package:flutter/material.dart';

class RealisticCricketAssets {
  // Team Color Palettes
  static const Color teamIndiaNavy = Color(0xFF0F2C59);
  static const Color teamIndiaGold = Color(0xFFF8B179);
  static const Color teamAustraliaYellow = Color(0xFFFFD700);
  static const Color teamAustraliaGreen = Color(0xFF006400);

  // ---------------------------------------------------------------------------
  // 1. REALISTIC CRICKETER FACE IDENTITY BADGE
  // ---------------------------------------------------------------------------
  static void drawCricketerFaceIdentity(
    Canvas canvas,
    Offset pos, {
    required String playerName,
    required bool isIndia,
    required double size,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    final nameLower = playerName.toLowerCase();
    Color jerseyColor = isIndia ? const Color(0xFF1E3A8A) : const Color(0xFFEAB308);
    Color capColor = isIndia ? const Color(0xFF0F172A) : const Color(0xFF15803D);
    Color skinTone = const Color(0xFFE5D0AC);

    bool hasBeard = nameLower.contains('rohit') || nameLower.contains('kohli') || nameLower.contains('bumrah');
    bool hasMustache = nameLower.contains('head') || nameLower.contains('rohit');
    bool isBlonde = nameLower.contains('cummins') || nameLower.contains('starc') || nameLower.contains('smith');

    if (isBlonde) {
      skinTone = const Color(0xFFFDE047).withOpacity(0.9); // Fair skin tone
      capColor = const Color(0xFF166534);
    }

    // Outer Glow Ring
    final ringPaint = Paint()
      ..color = (isIndia ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B)).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset.zero, size / 2, ringPaint);

    // Face Base Background (Circular Portrait)
    final bgPaint = Paint()..color = const Color(0xFF0B132B);
    canvas.drawCircle(Offset.zero, size / 2 - 1.5, bgPaint);

    // Torso / Collar
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, size * 0.35), radius: size * 0.42),
      math.pi,
      math.pi,
      true,
      Paint()..color = jerseyColor,
    );

    // Face Shape
    canvas.drawOval(Rect.fromCenter(center: Offset(0, size * 0.05), width: size * 0.48, height: size * 0.52), Paint()..color = skinTone);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(-size * 0.12, -size * 0.02), size * 0.04, eyePaint);
    canvas.drawCircle(Offset(size * 0.12, -size * 0.02), size * 0.04, eyePaint);

    // Eyebrows
    final eyebrowPaint = Paint()..color = const Color(0xFF0F172A)..strokeWidth = 1.8..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-size * 0.18, -size * 0.08), Offset(-size * 0.06, -size * 0.08), eyebrowPaint);
    canvas.drawLine(Offset(size * 0.06, -size * 0.08), Offset(size * 0.18, -size * 0.08), eyebrowPaint);

    // Beard / Mustache if applicable
    if (hasBeard) {
      final beardPaint = Paint()..color = const Color(0xFF1E293B).withOpacity(0.85);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(0, size * 0.16), width: size * 0.42, height: size * 0.28),
        0,
        math.pi,
        true,
        beardPaint,
      );
    } else if (hasMustache) {
      final stachePaint = Paint()..color = const Color(0xFF1E293B)..strokeWidth = 2.0..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(-size * 0.12, size * 0.1), Offset(size * 0.12, size * 0.1), stachePaint);
    }

    // Team Cap / Helmet
    final capPaint = Paint()..color = capColor;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, -size * 0.12), width: size * 0.52, height: size * 0.38),
      math.pi,
      math.pi,
      true,
      capPaint,
    );
    // Cap Visor
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-size * 0.3, -size * 0.12, size * 0.6, size * 0.08), const Radius.circular(2)),
      capPaint,
    );

    // Team Crest Badge on Cap
    canvas.drawCircle(Offset(0, -size * 0.22), size * 0.06, Paint()..color = isIndia ? const Color(0xFFF97316) : const Color(0xFFF59E0B));

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 2. REALISTIC BATTER DRAWING WITH FACE IDENTITY
  // ---------------------------------------------------------------------------
  static void drawRealisticBatter(
    Canvas canvas,
    Offset position, {
    required double scale,
    required bool isIndia,
    required double batAngle,
    required bool isStriker,
    String playerName = 'Rohit Sharma',
  }) {
    final jerseyColor = isIndia ? const Color(0xFF1E3A8A) : const Color(0xFFEAB308);
    final accentColor = isIndia ? const Color(0xFFF97316) : const Color(0xFF15803D);

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(scale);

    // Ground Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 12), width: 28, height: 10), shadowPaint);

    // 1. Batting Pads (Legs)
    final padPaint = Paint()..color = Colors.white;
    final padStrapPaint = Paint()..color = const Color(0xFFD1D5DB)..strokeWidth = 1.2..style = PaintingStyle.stroke;

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-10, 0, 8, 18), const Radius.circular(3)), padPaint);
    canvas.drawLine(const Offset(-10, 6), const Offset(-2, 6), padStrapPaint);
    canvas.drawLine(const Offset(-10, 12), const Offset(-2, 12), padStrapPaint);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, 2, 8, 18), const Radius.circular(3)), padPaint);
    canvas.drawLine(const Offset(2, 8), const Offset(10, 8), padStrapPaint);
    canvas.drawLine(const Offset(2, 14), const Offset(10, 14), padStrapPaint);

    // 2. Torso & Team Jersey
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -16, 18, 18), const Radius.circular(4)), Paint()..color = jerseyColor);
    canvas.drawRect(const Rect.fromLTWH(-9, -16, 18, 3), Paint()..color = accentColor);

    // 3. Batting Gloves & Arms
    final glovePaint = Paint()..color = Colors.white;
    canvas.drawLine(const Offset(-7, -12), const Offset(-2, -4), Paint()..color = jerseyColor..strokeWidth = 4..strokeCap = StrokeCap.round);
    canvas.drawLine(const Offset(7, -12), const Offset(4, -4), Paint()..color = jerseyColor..strokeWidth = 4..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(1, -3), 3.5, glovePaint);

    // 4. Helmet & Realistic Facial Identity Head
    drawCricketerFaceIdentity(canvas, const Offset(0, -21), playerName: playerName, isIndia: isIndia, size: 15);

    // 5. Cricket Bat with Wood Texture & Rubber Grip
    canvas.save();
    canvas.translate(2, -3);
    canvas.rotate(batAngle);

    canvas.drawLine(const Offset(0, 0), const Offset(0, -12), Paint()..color = accentColor..strokeWidth = 2.5);
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(Offset(-1, -3.0 * i), Offset(1, -3.0 * i), Paint()..color = Colors.black45..strokeWidth = 1);
    }

    final batPath = Path()
      ..moveTo(-3, 0)
      ..lineTo(3, 0)
      ..lineTo(4, 22)
      ..lineTo(-4, 22)
      ..close();

    final woodGradient = LinearGradient(
      colors: const [Color(0xFFDEB887), Color(0xFFD2B48C), Color(0xFFC19A6B)],
    );
    canvas.drawPath(batPath, Paint()..shader = woodGradient.createShader(const Rect.fromLTWH(-4, 0, 8, 22)));
    canvas.drawRect(const Rect.fromLTWH(-2.5, 2, 5, 8), Paint()..color = const Color(0xFFDC2626));

    canvas.restore();
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 3. REALISTIC BOWLER DRAWING WITH FACE IDENTITY
  // ---------------------------------------------------------------------------
  static void drawRealisticBowler(
    Canvas canvas,
    Offset position, {
    required double scale,
    required bool isIndia,
    required double armRotationProgress,
    String playerName = 'Jasprit Bumrah',
  }) {
    final jerseyColor = isIndia ? const Color(0xFF1E3A8A) : const Color(0xFFEAB308);

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(scale);

    // Ground Shadow
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 14), width: 32, height: 8), Paint()..color = Colors.black.withOpacity(0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Legs
    final legPaint = Paint()..color = jerseyColor..strokeWidth = 4.5..strokeCap = StrokeCap.round;
    final shoePaint = Paint()..color = Colors.white;

    canvas.drawLine(const Offset(-4, -2), const Offset(-12, 12), legPaint);
    canvas.drawCircle(const Offset(-13, 13), 2.5, shoePaint);

    canvas.drawLine(const Offset(2, -2), const Offset(8, 12), legPaint);
    canvas.drawCircle(const Offset(9, 13), 2.5, shoePaint);

    // Torso
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -18, 16, 17), const Radius.circular(4)), Paint()..color = jerseyColor);

    // Face Identity Head
    drawCricketerFaceIdentity(canvas, const Offset(0, -22), playerName: playerName, isIndia: isIndia, size: 14);

    // Bowling Arm & Ball Release
    final armAngle = math.pi * 1.5 - (armRotationProgress * math.pi * 1.8);
    final shoulderPos = const Offset(4, -15);
    final handPos = Offset(
      shoulderPos.dx + math.cos(armAngle) * 16,
      shoulderPos.dy + math.sin(armAngle) * 16,
    );

    canvas.drawLine(const Offset(-5, -15), const Offset(-10, -8), Paint()..color = jerseyColor..strokeWidth = 3.5..strokeCap = StrokeCap.round);
    canvas.drawLine(shoulderPos, handPos, Paint()..color = const Color(0xFFE5D0AC)..strokeWidth = 3.5..strokeCap = StrokeCap.round);
    canvas.drawCircle(handPos, 2, Paint()..color = const Color(0xFFE5D0AC));

    if (armRotationProgress < 0.5) {
      canvas.drawCircle(handPos, 3, Paint()..color = const Color(0xFFDC2626));
      canvas.drawCircle(handPos, 4.5, Paint()..color = const Color(0xFFEF4444).withOpacity(0.3));
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 4. ZING LED LIGHT-UP STUMPS & BAILS
  // ---------------------------------------------------------------------------
  static void drawZingStumps(Canvas canvas, Offset basePos, {required double scale, required bool isWicketHit}) {
    canvas.save();
    canvas.translate(basePos.dx, basePos.dy);
    canvas.scale(scale);

    final woodPaint = Paint()..color = const Color(0xFFD4A373)..strokeWidth = 2.8..strokeCap = StrokeCap.square;
    final ledGlowPaint = Paint()..color = const Color(0xFFEF4444)..strokeWidth = 3.2..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final ledLitPaint = Paint()..color = isWicketHit ? const Color(0xFFEF4444) : const Color(0xFFFEF08A)..strokeWidth = 2.8;

    final w = 7.0;
    final h = 22.0;

    for (int i = -1; i <= 1; i++) {
      final x = i * w;
      canvas.drawLine(Offset(x, 0), Offset(x, -h), woodPaint);
      if (isWicketHit) {
        canvas.drawLine(Offset(x, 0), Offset(x, -h), ledGlowPaint);
        canvas.drawLine(Offset(x, 0), Offset(x, -h), ledLitPaint);
      }
    }

    if (isWicketHit) {
      canvas.save();
      canvas.translate(-w, -h - 8);
      canvas.rotate(-0.4);
      canvas.drawLine(const Offset(-2, 0), Offset(w + 2, 0), ledGlowPaint);
      canvas.drawLine(const Offset(-2, 0), Offset(w + 2, 0), ledLitPaint);
      canvas.restore();

      canvas.save();
      canvas.translate(w / 2, -h - 12);
      canvas.rotate(0.5);
      canvas.drawLine(const Offset(-2, 0), Offset(w + 2, 0), ledGlowPaint);
      canvas.drawLine(const Offset(-2, 0), Offset(w + 2, 0), ledLitPaint);
      canvas.restore();
    } else {
      canvas.drawLine(Offset(-w - 1, -h), Offset(1, -h), woodPaint..strokeWidth = 1.8);
      canvas.drawLine(Offset(-1, -h), Offset(w + 1, -h), woodPaint..strokeWidth = 1.8);
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 5. HAWKEYE 3D BALL TRACKING TRAJECTORY
  // ---------------------------------------------------------------------------
  static void drawHawkeyeTrajectory(
    Canvas canvas,
    Size size, {
    required Offset releasePos,
    required Offset bouncePos,
    required Offset stumpPos,
    required double progress,
    required bool isWicket,
  }) {
    final trajectoryPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.5)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    path.moveTo(releasePos.dx, releasePos.dy);
    path.quadraticBezierTo(
      (releasePos.dx + bouncePos.dx) / 2,
      releasePos.dy + 15,
      bouncePos.dx,
      bouncePos.dy,
    );

    final endPos = isWicket ? stumpPos : Offset(stumpPos.dx + 25, stumpPos.dy - 10);
    path.quadraticBezierTo(
      (bouncePos.dx + endPos.dx) / 2,
      bouncePos.dy - 20,
      endPos.dx,
      endPos.dy,
    );

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, trajectoryPaint);

    canvas.drawCircle(bouncePos, 8, Paint()..color = const Color(0xFFF59E0B).withOpacity(0.4));
    canvas.drawCircle(bouncePos, 4, Paint()..color = const Color(0xFFF59E0B));

    if (isWicket && progress > 0.6) {
      final impactPaint = Paint()..color = const Color(0xFFEF4444);
      canvas.drawCircle(stumpPos, 7, impactPaint);
      canvas.drawCircle(stumpPos, 14, Paint()..color = const Color(0xFFEF4444).withOpacity(0.3));
    }
  }
}
