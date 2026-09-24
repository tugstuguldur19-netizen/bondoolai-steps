import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../state/app_state.dart';

/// Бондоолой: a Mongolian boy or girl in a deel, drawn procedurally.
/// [chubbiness] runs from 1.0 (chubby and cute, no steps yet) to 0.15
/// (fit: handsome / pretty).
class CharacterWidget extends StatelessWidget {
  final double chubbiness;
  final Map<ClothingSlot, String?> equipped;
  final Gender gender;
  final double size;

  const CharacterWidget({
    super.key,
    required this.chubbiness,
    required this.equipped,
    required this.gender,
    this.size = 260,
  });

  static const double aspect = 1.4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * aspect,
      child: CustomPaint(
        painter: _CharacterPainter(
          chubbiness: chubbiness,
          equipped: equipped,
          female: gender == Gender.female,
        ),
      ),
    );
  }
}

const _skin = Color(0xFFE0AC7E);
const _skinShade = Color(0xFFC88F63);
const _ink = Color(0xFF4A2E1B);
const _hair = Color(0xFF17130F);
const _hairShine = Color(0xFF3A3029);

const _defaultDeel = Color(0xFF5C6B7A);
const _defaultDeelTrim = Color(0xFF34404C);
const _defaultDeelFemale = Color(0xFF8E4C6E);
const _defaultDeelTrimFemale = Color(0xFFE8C45A);
const _defaultBelt = Color(0xFF8D6E63);
const _defaultBoots = Color(0xFF5D4037);
const _defaultBootsAccent = Color(0xFF8D6E63);

Color _darken(Color c, [double amount = 0.22]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

class _CharacterPainter extends CustomPainter {
  final double chubbiness;
  final Map<ClothingSlot, String?> equipped;
  final bool female;

  _CharacterPainter({
    required this.chubbiness,
    required this.equipped,
    required this.female,
  });

  ClothingItem? _item(ClothingSlot slot) {
    final id = equipped[slot];
    return id == null ? null : itemById(id);
  }

  Paint _fill(Color c) => Paint()..color = c;

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    // Work in a 100 x 140 unit space; the figure spans y = 0..121 after the
    // 14-unit headroom reserved for tall hats.
    canvas.save();
    canvas.scale(size.width / 100);
    canvas.translate(0, 14);

    final c = chubbiness.clamp(0.15, 1.0);
    final bodyScale = 0.74 + 0.4 * c;
    final sh = 17 * bodyScale * (female ? 0.9 : 1.0); // shoulder half-width
    final bw = (female ? 12.5 : 14) * bodyScale + 14 * c; // belly half-width
    final hw = 18.5 * bodyScale * (female ? 1.08 : 1.0); // hem half-width
    // Faces read as "cute" with a bigger, rounder head and "grown-up" with a
    // smaller, narrower one.
    final headScale = 0.95 + 0.17 * c;
    final fw = 30 * (0.86 + 0.2 * c) * (female ? 0.95 : 1.0);

    final deel = _item(ClothingSlot.deel);
    final deelColor = deel?.color ?? (female ? _defaultDeelFemale : _defaultDeel);
    final trimColor = deel?.accent ?? (female ? _defaultDeelTrimFemale : _defaultDeelTrim);
    final accessory = _item(ClothingSlot.accessory);

    if (accessory?.accessoryStyle == AccessoryStyle.bow) {
      _drawBow(canvas, accessory!);
    }
    if (female) _withHeadScale(canvas, headScale, () => _drawBackHair(canvas, fw));
    _drawBoots(canvas);
    _drawDeel(canvas, sh, bw, hw, deelColor, trimColor);
    _drawBelt(canvas, bw);
    _drawArms(canvas, sh, c, deelColor, trimColor);
    _drawNeckAndCollar(canvas, trimColor);
    if (accessory?.accessoryStyle == AccessoryStyle.khadag) {
      _drawKhadag(canvas, accessory!);
    } else if (accessory?.accessoryStyle == AccessoryStyle.medal) {
      _drawMedal(canvas, accessory!);
    }
    _withHeadScale(canvas, headScale, () {
      if (female) _drawBraids(canvas, fw);
      _drawHead(canvas, c, fw);
      final hat = _item(ClothingSlot.hat);
      if (hat != null) _drawHat(canvas, hat);
    });

    canvas.restore();
  }

  /// Scales the head around the chin so it stays attached to the neck.
  void _withHeadScale(Canvas canvas, double s, void Function() draw) {
    canvas.save();
    canvas.translate(50, 39.5);
    canvas.scale(s);
    canvas.translate(-50, -39.5);
    draw();
    canvas.restore();
  }

  void _drawBoots(Canvas canvas) {
    final boots = _item(ClothingSlot.boots);
    final color = boots?.color ?? _defaultBoots;
    final accent = boots?.accent ?? _defaultBootsAccent;
    final outline = _stroke(_darken(color, 0.25), 0.6);

    for (final side in [-1.0, 1.0]) {
      final x = 50 + side * 7;
      final shaft = RRect.fromLTRBR(x - 5, 95, x + 5, 118, const Radius.circular(2));
      // Foot with the traditional upturned toe, pointing outward.
      final toeX = x + side * 11;
      final foot = Path()
        ..moveTo(x - side * 5, 116)
        ..lineTo(x - side * 5, 121)
        ..lineTo(x + side * 6, 121)
        ..quadraticBezierTo(toeX, 121, toeX + side * 0.5, 115.5)
        ..quadraticBezierTo(x + side * 8, 118, x + side * 5, 116)
        ..close();
      canvas.drawPath(foot, _fill(color));
      canvas.drawPath(foot, outline);
      canvas.drawRRect(shaft, _fill(color));
      canvas.drawRRect(shaft, outline);
      // Patterned band and a small diamond ornament.
      canvas.drawRect(Rect.fromLTRB(x - 5, 110, x + 5, 112), _fill(accent));
      final diamond = Path()
        ..moveTo(x, 101)
        ..lineTo(x + 2.2, 104)
        ..lineTo(x, 107)
        ..lineTo(x - 2.2, 104)
        ..close();
      canvas.drawPath(diamond, _fill(accent));
    }
  }

  void _drawDeel(Canvas canvas, double sh, double bw, double hw,
      Color deelColor, Color trimColor) {
    final body = Path()
      ..moveTo(45, 42)
      ..lineTo(50 - sh + 3, 43.5)
      ..quadraticBezierTo(50 - sh, 44, 50 - sh, 48)
      ..cubicTo(50 - sh - 1, 55, 50 - bw, 57, 50 - bw, 64)
      ..cubicTo(50 - bw, 73, 50 - hw + 1, 86, 50 - hw, 99)
      ..lineTo(50 + hw, 99)
      ..cubicTo(50 + hw - 1, 86, 50 + bw, 73, 50 + bw, 64)
      ..cubicTo(50 + bw, 57, 50 + sh + 1, 55, 50 + sh, 48)
      ..quadraticBezierTo(50 + sh, 44, 50 + sh - 3, 43.5)
      ..lineTo(55, 42)
      ..close();
    canvas.drawPath(body, _fill(deelColor));
    canvas.drawPath(body, _stroke(_darken(deelColor, 0.28), 0.7));

    // Энгэр: the curved front panel edge sweeping to the wearer's right side
    // and down to the hem, trimmed in the accent color.
    final lapel = Path()
      ..moveTo(53, 43)
      ..quadraticBezierTo(47, 52, 50 - sh + 3, 54)
      ..cubicTo(50 - bw + 2, 62, 50 - bw + 3, 80, 50 - hw + 4, 98);
    canvas.drawPath(lapel, _stroke(trimColor, 2.4));
    canvas.drawLine(
      Offset(50 - hw + 1, 98),
      Offset(50 + hw - 1, 98),
      _stroke(trimColor, 1.8),
    );

    // Товч: knot buttons along the lapel.
    final buttonPaint = _fill(const Color(0xFFE8C45A));
    for (final p in [
      const Offset(52, 45.5),
      const Offset(47.5, 50),
      Offset(50 - sh + 4, 55),
    ]) {
      canvas.drawCircle(p, 1.2, buttonPaint);
      canvas.drawCircle(p, 1.2, _stroke(_ink, 0.3));
    }
  }

  void _drawBelt(Canvas canvas, double bw) {
    final belt = _item(ClothingSlot.belt);
    final color = belt?.color ?? _defaultBelt;
    final dark = _darken(color, 0.18);

    final band = RRect.fromLTRBR(50 - bw + 0.5, 61, 50 + bw - 0.5, 67, const Radius.circular(2));
    canvas.drawRRect(band, _fill(color));
    for (final y in [63.0, 65.0]) {
      canvas.drawLine(Offset(50 - bw + 2, y), Offset(50 + bw - 2, y), _stroke(dark, 0.4));
    }
    // Knot and hanging tails on the wearer's left.
    final knotX = 50 + bw * 0.55;
    final tails = Path()
      ..moveTo(knotX - 1.5, 65)
      ..quadraticBezierTo(knotX - 3, 72, knotX - 2, 79)
      ..lineTo(knotX + 1.2, 79)
      ..quadraticBezierTo(knotX, 72, knotX + 1, 65)
      ..moveTo(knotX + 0.5, 65)
      ..quadraticBezierTo(knotX + 3, 71, knotX + 4.5, 76)
      ..lineTo(knotX + 7, 75)
      ..quadraticBezierTo(knotX + 4.5, 70, knotX + 2.5, 65);
    canvas.drawPath(tails, _fill(color));
    canvas.drawPath(tails, _stroke(dark, 0.4));
    canvas.drawOval(Rect.fromCenter(center: Offset(knotX, 64), width: 5, height: 5), _fill(dark));
  }

  void _drawArms(Canvas canvas, double sh, double c, Color deelColor, Color trimColor) {
    final armW = 8 * (0.85 + 0.2 * c) * (female ? 0.9 : 1.0);
    final outline = _darken(deelColor, 0.28);

    for (final side in [-1.0, 1.0]) {
      final out = 5 + 7 * c; // chubby arms rest on the outside of the belly
      final shoulder = Offset(50 + side * (sh - 2), 48);
      final wrist = Offset(50 + side * (sh + out), 76);
      final cuffStart = Offset.lerp(shoulder, wrist, 0.86)!;

      canvas.drawLine(shoulder, wrist, _stroke(outline, armW + 1.2));
      canvas.drawLine(shoulder, wrist, _stroke(deelColor, armW));
      // Ханцуй: contrasting cuff.
      canvas.drawLine(cuffStart, wrist, _stroke(trimColor, armW));

      final hand = Offset(50 + side * (sh + out + 1), 80);
      canvas.drawCircle(hand, female ? 3.0 : 3.4, _fill(_skin));
      canvas.drawCircle(hand, female ? 3.0 : 3.4, _stroke(_skinShade, 0.5));
    }
  }

  void _drawNeckAndCollar(Canvas canvas, Color trimColor) {
    final neckHalf = female ? 3.4 : 4.0;
    canvas.drawRect(Rect.fromLTRB(50 - neckHalf, 36, 50 + neckHalf, 43), _fill(_skinShade));
    final collar = Path()
      ..moveTo(44.5, 44.5)
      ..lineTo(45, 40.5)
      ..quadraticBezierTo(50, 42.5, 55, 40.5)
      ..lineTo(55.5, 44.5)
      ..quadraticBezierTo(50, 46.5, 44.5, 44.5)
      ..close();
    canvas.drawPath(collar, _fill(trimColor));
    canvas.drawPath(collar, _stroke(_darken(trimColor, 0.2), 0.4));
  }

  void _drawBackHair(Canvas canvas, double fw) {
    final back = Path()
      ..moveTo(50 - fw / 2 - 2, 20)
      ..cubicTo(50 - fw * 0.66, 1, 50 + fw * 0.66, 1, 50 + fw / 2 + 2, 20)
      ..lineTo(50 + fw / 2 + 3, 44)
      ..quadraticBezierTo(50, 48, 50 - fw / 2 - 3, 44)
      ..close();
    canvas.drawPath(back, _fill(_hair));
  }

  /// Two traditional braids falling over the shoulders, tied with red.
  void _drawBraids(Canvas canvas, double fw) {
    for (final side in [-1.0, 1.0]) {
      final start = Offset(50 + side * (fw / 2 - 1), 30);
      final control = Offset(50 + side * (fw / 2 + 3.5), 46);
      final end = Offset(50 + side * (fw / 2 - 1.5), 68);
      const segments = 9;
      for (var i = 0; i < segments; i++) {
        final t = i / (segments - 1);
        final p = _quad(start, control, end, t);
        final w = 4.6 - 1.2 * t;
        final rect = Rect.fromCenter(center: p, width: w, height: 3.6);
        canvas.drawOval(rect, _fill(_hair));
        canvas.drawArc(rect, 3.4, 2.4, false, _stroke(_hairShine, 0.45));
      }
      canvas.drawOval(
        Rect.fromCenter(center: end + const Offset(0, 2.4), width: 3.6, height: 2.2),
        _fill(const Color(0xFFD32F2F)),
      );
      final tuft = Path()
        ..moveTo(end.dx - 1.4, end.dy + 3)
        ..quadraticBezierTo(end.dx, end.dy + 7.5, end.dx + 1.4, end.dy + 3)
        ..close();
      canvas.drawPath(tuft, _fill(_hair));
    }
  }

  Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  void _drawHead(Canvas canvas, double c, double fw) {
    // Rounder jaw when chubby; defined jaw (male) or soft V-line (female)
    // when fit.
    final jaw = female ? 0.24 + 0.2 * c : 0.26 + 0.16 * c;

    // Ears.
    for (final side in [-1.0, 1.0]) {
      final ear = Rect.fromCenter(center: Offset(50 + side * fw / 2, 24), width: 5, height: 8);
      canvas.drawOval(ear, _fill(_skin));
      canvas.drawOval(ear, _stroke(_skinShade, 0.5));
    }

    final face = Path()
      ..moveTo(50, 5)
      ..cubicTo(50 + fw * 0.55, 5, 50 + fw / 2, 16, 50 + fw / 2, 24)
      ..cubicTo(50 + fw / 2, 32, 50 + fw * jaw, 38, 50, 39.5)
      ..cubicTo(50 - fw * jaw, 38, 50 - fw / 2, 32, 50 - fw / 2, 24)
      ..cubicTo(50 - fw / 2, 16, 50 - fw * 0.55, 5, 50, 5)
      ..close();
    canvas.drawPath(face, _fill(_skin));
    canvas.drawPath(face, _stroke(_skinShade, 0.6));

    if (c > 0.55) {
      final chin = Path()
        ..moveTo(45.5, 39)
        ..quadraticBezierTo(50, 41.8, 54.5, 39);
      canvas.drawPath(chin, _stroke(_skinShade.withValues(alpha: (c - 0.55) * 2), 0.6));
    }

    // Rosy cheeks (bigger when chubby).
    final cheekR = 2.8 + 1.2 * c;
    final cheek = _fill(const Color(0xFFD9534F).withValues(alpha: female ? 0.4 : 0.32));
    canvas.drawCircle(Offset(50 - fw * 0.3, 28.5), cheekR, cheek);
    canvas.drawCircle(Offset(50 + fw * 0.3, 28.5), cheekR, cheek);

    // Eyes: big and round when chubby (cute), almond with an upward outer
    // tilt when fit (handsome / pretty).
    final open = 1.7 + 1.4 * c;
    final lower = 0.9 + 0.9 * c;
    for (final side in [-1.0, 1.0]) {
      final inner = 50 + side * 2.8;
      final outer = 50 + side * (9 - 0.6 * c);
      final mid = 50 + side * 5.9;
      final outerY = 22.6 + 0.9 * c;
      final eye = Path()
        ..moveTo(inner, 23.8)
        ..quadraticBezierTo(mid, 23.8 - 2 * open, outer, outerY)
        ..quadraticBezierTo(mid, 23.8 + 2 * lower, inner, 23.8)
        ..close();
      canvas.drawPath(eye, _fill(const Color(0xFF2A1A10)));
      final shine = _fill(Colors.white);
      canvas.drawCircle(Offset(mid - side * 0.6, 22.9 - 0.4 * c), 0.45 + 0.6 * c, shine);
      if (c > 0.5) {
        canvas.drawCircle(Offset(mid + side * 0.8, 24.2 + 0.4 * c), 0.35 * c, shine);
      }
      if (female) {
        // Lashes at the outer corner.
        final lash = _stroke(const Color(0xFF2A1A10), 0.5);
        canvas.drawLine(Offset(outer, outerY), Offset(outer + side * 1.6, outerY - 1.3), lash);
        canvas.drawLine(
          Offset(outer - side * 1.2, outerY - 0.7),
          Offset(outer - side * 0.2, outerY - 2.1),
          lash,
        );
      }
    }

    // Eyebrows: strong and straight for him, thin arches for her.
    final browY = 19.6 - 0.6 * c;
    if (female) {
      final brow = _stroke(_hair, 0.9);
      for (final side in [-1.0, 1.0]) {
        final path = Path()
          ..moveTo(50 + side * 3, browY + 0.4)
          ..quadraticBezierTo(50 + side * 6.5, browY - 1.6, 50 + side * 9.2, browY + 0.6);
        canvas.drawPath(path, brow);
      }
    } else {
      final brow = _stroke(_hair, 1.5);
      canvas.drawLine(Offset(41, browY - 0.7), Offset(47.2, browY), brow);
      canvas.drawLine(Offset(52.8, browY), Offset(59, browY - 0.7), brow);
    }

    // Nose.
    final nose = Path()
      ..moveTo(50, 24.5)
      ..quadraticBezierTo(49, 28, 48.6, 29.4)
      ..quadraticBezierTo(50, 30.2, 51.4, 29.4);
    canvas.drawPath(nose, _stroke(_skinShade, female ? 0.55 : 0.7));

    if (female) {
      final lips = Path()
        ..moveTo(47, 32.4)
        ..quadraticBezierTo(50, 35, 53, 32.4)
        ..quadraticBezierTo(50, 33.3, 47, 32.4)
        ..close();
      canvas.drawPath(lips, _fill(const Color(0xFFC94A64)));
    } else {
      final mouth = Path()
        ..moveTo(46, 32.4)
        ..quadraticBezierTo(50, 35, 54, 32.4);
      canvas.drawPath(mouth, _stroke(const Color(0xFF8A3B2A), 1.0));
    }

    if (female) {
      _drawFemaleFrontHair(canvas, fw);
      // Earrings.
      for (final side in [-1.0, 1.0]) {
        final p = Offset(50 + side * (fw / 2 + 0.4), 29);
        canvas.drawCircle(p, 1.1, _fill(const Color(0xFFE57373)));
        canvas.drawCircle(p, 1.1, _stroke(const Color(0xFFE8C45A), 0.4));
      }
    } else {
      _drawMaleHair(canvas, fw);
    }
  }

  void _drawMaleHair(Canvas canvas, double fw) {
    final hair = Path()
      ..moveTo(50 - fw / 2 - 0.5, 23)
      ..cubicTo(50 - fw * 0.6, 8, 50 - fw * 0.35, 2.5, 50, 2.5)
      ..cubicTo(50 + fw * 0.4, 2.5, 50 + fw * 0.6, 8, 50 + fw / 2 + 0.5, 23)
      ..quadraticBezierTo(50 + fw / 2 - 1, 17, 50 + fw / 2 - 3, 15)
      ..quadraticBezierTo(52, 15.5, 44, 12.5)
      ..quadraticBezierTo(42, 16, 50 - fw / 2 + 2, 17)
      ..quadraticBezierTo(50 - fw / 2, 19, 50 - fw / 2 - 0.5, 23)
      ..close();
    canvas.drawPath(hair, _fill(_hair));
  }

  void _drawFemaleFrontHair(Canvas canvas, double fw) {
    // Center-parted hair framing the face.
    final hair = Path()
      ..moveTo(50 - fw / 2 - 0.8, 27)
      ..cubicTo(50 - fw * 0.62, 8, 50 - fw * 0.35, 2, 50, 2.3)
      ..cubicTo(50 + fw * 0.35, 2, 50 + fw * 0.62, 8, 50 + fw / 2 + 0.8, 27)
      ..quadraticBezierTo(50 + fw / 2 - 1.5, 18, 50 + fw * 0.3, 12)
      ..quadraticBezierTo(53, 9, 50, 7)
      ..quadraticBezierTo(47, 9, 50 - fw * 0.3, 12)
      ..quadraticBezierTo(50 - fw / 2 + 1.5, 18, 50 - fw / 2 - 0.8, 27)
      ..close();
    canvas.drawPath(hair, _fill(_hair));
    final shine = Path()
      ..moveTo(50 - fw * 0.3, 5)
      ..quadraticBezierTo(50 - fw * 0.15, 3.4, 50 - 2, 3.6);
    canvas.drawPath(shine, _stroke(_hairShine, 0.8));
  }

  void _drawHat(Canvas canvas, ClothingItem hat) {
    switch (hat.hatStyle) {
      case HatStyle.toortsog:
        final cone = Path()
          ..moveTo(35.5, 10)
          ..quadraticBezierTo(50, -13, 64.5, 10)
          ..close();
        canvas.drawPath(cone, _fill(hat.color));
        // Залаа: red tassel threads flowing down the crown.
        final tassel = _stroke(hat.accent, 0.7);
        for (final dx in [-6.0, -3.0, 0.0, 3.0, 6.0]) {
          canvas.drawLine(const Offset(50, -6), Offset(50 + dx, 6), tassel);
        }
        canvas.drawCircle(const Offset(50, -6.5), 2.4, _fill(hat.accent));
        canvas.drawRRect(
          RRect.fromLTRBR(33, 8, 67, 14.5, const Radius.circular(3)),
          _fill(const Color(0xFF1C1C1C)),
        );
      case HatStyle.loovuuz:
        final fur = _fill(hat.accent);
        final furDark = _stroke(_darken(hat.accent, 0.18), 0.6);
        for (final x in [31.0, 62.0]) {
          final flap = RRect.fromLTRBR(x, 8, x + 7, 28, const Radius.circular(3.5));
          canvas.drawRRect(flap, fur);
          canvas.drawRRect(flap, furDark);
        }
        final dome = Path()
          ..moveTo(37, 6)
          ..quadraticBezierTo(50, -15, 63, 6)
          ..close();
        canvas.drawPath(dome, _fill(hat.color));
        canvas.drawCircle(const Offset(50, -5), 1.8, _fill(const Color(0xFFE8C45A)));
        final band = RRect.fromLTRBR(32, 3.5, 68, 13, const Radius.circular(5));
        canvas.drawRRect(band, fur);
        for (var x = 35.0; x < 66; x += 3.2) {
          canvas.drawLine(Offset(x, 5.5), Offset(x + 1, 11), furDark);
        }
      case HatStyle.janjin:
        final dome = Path()
          ..moveTo(38, 9)
          ..quadraticBezierTo(38, -5, 50, -5)
          ..quadraticBezierTo(62, -5, 62, 9)
          ..close();
        canvas.drawPath(dome, _fill(hat.color));
        final fringe = _stroke(hat.accent, 0.8);
        for (final dx in [-7.0, -3.5, 0.0, 3.5, 7.0]) {
          canvas.drawLine(const Offset(50, -4), Offset(50 + dx, 4), fringe);
        }
        canvas.drawLine(const Offset(50, -5), const Offset(50, -11), _stroke(_darken(hat.color), 1.2));
        canvas.drawCircle(const Offset(50, -12), 2.2, _fill(hat.accent));
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(50, 9.5), width: 40, height: 7),
          _fill(_darken(hat.color, 0.15)),
        );
      case null:
        break;
    }
  }

  void _drawKhadag(Canvas canvas, ClothingItem item) {
    final paint = _stroke(item.color, 4.2);
    final edge = _stroke(item.accent, 0.5);
    for (final side in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(50 + side * 5, 42)
        ..quadraticBezierTo(50 + side * 8, 55, 50 + side * 7, 72);
      canvas.drawPath(path, paint);
      canvas.drawPath(path, edge);
      for (final dx in [-1.5, 0.0, 1.5]) {
        canvas.drawLine(
          Offset(50 + side * 7 + dx, 73.5),
          Offset(50 + side * 7 + dx, 76.5),
          _stroke(item.color, 0.5),
        );
      }
    }
  }

  void _drawMedal(Canvas canvas, ClothingItem item) {
    final ribbon = Path()
      ..moveTo(46.5, 43.5)
      ..lineTo(50, 52)
      ..lineTo(53.5, 43.5);
    canvas.drawPath(ribbon, _stroke(item.accent, 2.2));
    canvas.drawCircle(const Offset(50, 55), 3.8, _fill(item.color));
    canvas.drawCircle(const Offset(50, 55), 3.8, _stroke(_darken(item.color, 0.25), 0.6));
    canvas.drawCircle(const Offset(50, 55), 2.0, _fill(_darken(item.color, 0.12)));
  }

  void _drawBow(Canvas canvas, ClothingItem item) {
    final bow = Path()
      ..moveTo(63, 36)
      ..quadraticBezierTo(92, 64, 71, 97);
    canvas.drawPath(bow, _stroke(item.color, 2.4));
    canvas.drawLine(const Offset(63, 36), const Offset(71, 97), _stroke(item.accent, 0.5));
    for (final dx in [0.0, 3.0]) {
      canvas.drawLine(Offset(36 + dx, 50), Offset(28 + dx, 32), _stroke(_darken(item.color, 0.05), 0.9));
      final feather = Path()
        ..moveTo(28 + dx, 32)
        ..lineTo(26 + dx, 35.5)
        ..lineTo(29.5 + dx, 35)
        ..close();
      canvas.drawPath(feather, _fill(const Color(0xFFD32F2F)));
    }
  }

  String get _equippedSignature =>
      ClothingSlot.values.map((s) => equipped[s] ?? '-').join('|');

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) {
    return oldDelegate.chubbiness != chubbiness ||
        oldDelegate.female != female ||
        oldDelegate._equippedSignature != _equippedSignature;
  }
}
