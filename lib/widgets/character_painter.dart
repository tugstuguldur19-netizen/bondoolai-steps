import 'package:flutter/material.dart';

import '../models/clothing_item.dart';

/// Simple procedurally-drawn placeholder character. The body width scales
/// with [chubbiness] (1.0 = chubbiest, 0.15 = slimmest) and equipped
/// clothing is layered on top. Swap this painter out later for real art.
class CharacterWidget extends StatelessWidget {
  final double chubbiness;
  final Map<ClothingSlot, String?> equipped;
  final double size;

  const CharacterWidget({
    super.key,
    required this.chubbiness,
    required this.equipped,
    this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.25,
      child: CustomPaint(
        painter: _CharacterPainter(
          chubbiness: chubbiness,
          equipped: equipped,
        ),
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final double chubbiness;
  final Map<ClothingSlot, String?> equipped;

  _CharacterPainter({required this.chubbiness, required this.equipped});

  Color? _colorFor(ClothingSlot slot) {
    final id = equipped[slot];
    if (id == null) return null;
    return itemById(id).color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // chubbiness in [0.15, 1.0] -> torso width multiplier [0.62, 1.0]
    final torsoScale = 0.62 + 0.38 * chubbiness;
    final skin = const Color(0xFFF2C199);

    final headRadius = w * 0.20;
    final headCenter = Offset(cx, h * 0.16);

    final torsoWidth = w * 0.62 * torsoScale;
    final torsoHeight = h * 0.42;
    final torsoTop = h * 0.30;
    final torsoRect = Rect.fromCenter(
      center: Offset(cx, torsoTop + torsoHeight / 2),
      width: torsoWidth,
      height: torsoHeight,
    );
    final torsoRRect = RRect.fromRectAndRadius(
      torsoRect,
      Radius.circular(torsoWidth * 0.35),
    );

    final legWidth = w * 0.16 * (0.85 + 0.15 * chubbiness);
    final legHeight = h * 0.28;
    final legTop = torsoRect.bottom - 4;
    final legGap = torsoWidth * 0.12;
    final leftLegRect = Rect.fromLTWH(
      cx - legGap / 2 - legWidth,
      legTop,
      legWidth,
      legHeight,
    );
    final rightLegRect = Rect.fromLTWH(
      cx + legGap / 2,
      legTop,
      legWidth,
      legHeight,
    );

    final armWidth = w * 0.14 * (0.85 + 0.15 * chubbiness);
    final armHeight = h * 0.3;
    final leftArmRect = Rect.fromLTWH(
      torsoRect.left - armWidth * 0.7,
      torsoTop + 6,
      armWidth,
      armHeight,
    );
    final rightArmRect = Rect.fromLTWH(
      torsoRect.right - armWidth * 0.3,
      torsoTop + 6,
      armWidth,
      armHeight,
    );

    final skinPaint = Paint()..color = skin;
    final outline = Paint()
      ..color = const Color(0xFF7A4B28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Legs (skin/pants underlayer)
    final legsPaint = Paint()..color = _colorFor(ClothingSlot.bottom) ?? skin;
    for (final r in [leftLegRect, rightLegRect]) {
      final rr = RRect.fromRectAndRadius(r, Radius.circular(legWidth * 0.3));
      canvas.drawRRect(rr, legsPaint);
      canvas.drawRRect(rr, outline);
    }

    // Shoes
    final shoeColor = _colorFor(ClothingSlot.shoes);
    if (shoeColor != null) {
      final shoePaint = Paint()..color = shoeColor;
      for (final r in [leftLegRect, rightLegRect]) {
        final shoeRect = Rect.fromLTWH(
          r.left - 4,
          r.bottom - 10,
          r.width + 8,
          16,
        );
        final rr = RRect.fromRectAndRadius(shoeRect, const Radius.circular(8));
        canvas.drawRRect(rr, shoePaint);
        canvas.drawRRect(rr, outline);
      }
    }

    // Arms
    for (final r in [leftArmRect, rightArmRect]) {
      final rr = RRect.fromRectAndRadius(r, Radius.circular(armWidth * 0.4));
      canvas.drawRRect(rr, skinPaint);
      canvas.drawRRect(rr, outline);
    }

    // Torso (shirt)
    final topPaint = Paint()..color = _colorFor(ClothingSlot.top) ?? const Color(0xFF64B5F6);
    canvas.drawRRect(torsoRRect, topPaint);
    canvas.drawRRect(torsoRRect, outline);

    // Head
    canvas.drawCircle(headCenter, headRadius, skinPaint);
    canvas.drawCircle(headCenter, headRadius, outline);

    // Face: eyes + smile
    final eyePaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius * 0.35, headCenter.dy - headRadius * 0.05),
      headRadius * 0.08,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headRadius * 0.35, headCenter.dy - headRadius * 0.05),
      headRadius * 0.08,
      eyePaint,
    );
    final smilePath = Path()
      ..moveTo(headCenter.dx - headRadius * 0.35, headCenter.dy + headRadius * 0.25)
      ..quadraticBezierTo(
        headCenter.dx,
        headCenter.dy + headRadius * 0.55,
        headCenter.dx + headRadius * 0.35,
        headCenter.dy + headRadius * 0.25,
      );
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = const Color(0xFF3E2723)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Glasses
    final glassesColor = _colorFor(ClothingSlot.glasses);
    if (glassesColor != null) {
      final gPaint = Paint()
        ..color = glassesColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      final lensR = headRadius * 0.22;
      final ly = headCenter.dy - headRadius * 0.05;
      final lxL = headCenter.dx - headRadius * 0.35;
      final lxR = headCenter.dx + headRadius * 0.35;
      canvas.drawCircle(Offset(lxL, ly), lensR, gPaint);
      canvas.drawCircle(Offset(lxR, ly), lensR, gPaint);
      canvas.drawLine(
        Offset(lxL + lensR, ly),
        Offset(lxR - lensR, ly),
        gPaint,
      );
    }

    // Hat
    final hatColor = _colorFor(ClothingSlot.hat);
    if (hatColor != null) {
      final hatPaint = Paint()..color = hatColor;
      final brimRect = Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy - headRadius * 0.75),
        width: headRadius * 2.3,
        height: headRadius * 0.35,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(brimRect, const Radius.circular(6)),
        hatPaint,
      );
      final topRect = Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy - headRadius * 1.15),
        width: headRadius * 1.3,
        height: headRadius * 0.7,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(topRect, const Radius.circular(8)),
        hatPaint,
      );
    }
  }

  String get _equippedSignature =>
      ClothingSlot.values.map((s) => equipped[s] ?? '-').join('|');

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) {
    return oldDelegate.chubbiness != chubbiness ||
        oldDelegate._equippedSignature != _equippedSignature;
  }
}
