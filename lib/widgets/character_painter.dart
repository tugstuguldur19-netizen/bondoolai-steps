import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../state/app_state.dart';

/// Бондоолой: a Mongolian boy or girl, drawn procedurally in a soft,
/// shaded "3D toy" style. [chubbiness] runs from 1.0 (chubby and cute, no
/// steps yet) to 0.15 (fit: handsome / pretty).
///
/// Without a deel the character wears a t-shirt and shorts; while chubby,
/// the boy's belly pokes out under the t-shirt.
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

const _skinLight = Color(0xFFF8D9BC);
const _skin = Color(0xFFEDBF98);
const _skinShade = Color(0xFFD69C74);
const _hairDark = Color(0xFF1C130D);
const _hairLight = Color(0xFF4B3528);
const _irisLight = Color(0xFF8A5A34);
const _irisDark = Color(0xFF2C180B);
const _lidInk = Color(0xFF2A1A10);
const _gold = Color(0xFFE2B447);

const _teeMale = Color(0xFF6FA8DC);
const _teeFemale = Color(0xFFF2A7BF);
const _shortsMale = Color(0xFF33425E);
const _shortsFemale = Color(0xFF5E4B7C);
const _defaultBoots = Color(0xFF5A3A28);
const _defaultBootsAccent = Color(0xFF7B5A44);
const _defaultBelt = Color(0xFFB08A60);

Color _darken(Color c, [double amount = 0.22]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

Color _lighten(Color c, [double amount = 0.1]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
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

  /// Horizontal shading that makes a flat shape read as a rounded surface.
  Paint _round(Rect r, Color c) => Paint()
    ..shader = LinearGradient(
      colors: [_darken(c, 0.12), _lighten(c, 0.07), c, _darken(c, 0.15)],
      stops: const [0, 0.36, 0.62, 1],
    ).createShader(r);

  Paint _skinPaint(Rect r) => Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.25, -0.35),
      radius: 0.95,
      colors: const [_skinLight, _skin, _skinShade],
      stops: const [0, 0.55, 1],
    ).createShader(r);

  Paint _sphere(Offset center, double r, Color c) => Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.35, -0.4),
      colors: [_lighten(c, 0.22), c, _darken(c, 0.2)],
      stops: const [0, 0.55, 1],
    ).createShader(Rect.fromCircle(center: center, radius: r));

  @override
  void paint(Canvas canvas, Size size) {
    // 100 x 140 unit space; the figure spans y = 0..122 below 14 units of
    // headroom for tall hats.
    canvas.save();
    canvas.scale(size.width / 100);
    canvas.translate(0, 14);

    final c = chubbiness.clamp(0.15, 1.0);
    final g = _Geometry(c, female);
    final deel = _item(ClothingSlot.deel);
    final accessory = _item(ClothingSlot.accessory);

    // Soft ground shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 122), width: 34 + 10 * c, height: 4.5),
      _fill(Colors.black.withValues(alpha: 0.13)),
    );

    if (accessory?.accessoryStyle == AccessoryStyle.bow) _drawQuiverBack(canvas, accessory!);
    if (female) _headSpace(canvas, g, () => _drawBackHair(canvas, g));

    if (deel != null) {
      _drawBoots(canvas, legsVisible: false);
      _drawDeel(canvas, g, deel);
      _drawBelt(canvas, g);
      _drawArms(canvas, g, sleeve: deel.color, cuff: deel.accent, longSleeves: true);
      _drawNeck(canvas);
      _drawStandCollar(canvas, deel.accent);
    } else {
      _drawLegs(canvas, g);
      if (_item(ClothingSlot.boots) != null) {
        _drawBoots(canvas, legsVisible: true);
      } else {
        _drawSneakers(canvas, g);
      }
      _drawNeck(canvas);
      _drawCasualTop(canvas, g);
      _drawArms(canvas, g, sleeve: female ? _teeFemale : _teeMale, cuff: null, longSleeves: false);
    }

    if (accessory?.accessoryStyle == AccessoryStyle.bow) _drawQuiverStrap(canvas, g, accessory!);
    if (accessory?.accessoryStyle == AccessoryStyle.khadag) _drawKhadag(canvas, accessory!);
    if (accessory?.accessoryStyle == AccessoryStyle.medal) _drawMedal(canvas, accessory!);

    _headSpace(canvas, g, () {
      if (female) _drawBraids(canvas, g);
      _drawHead(canvas, g);
      final hat = _item(ClothingSlot.hat);
      if (hat != null) _drawHat(canvas, hat);
    });

    canvas.restore();
  }

  /// Draws in "head space": scaled around the chin so the head stays on the
  /// neck while it grows (cute) or shrinks (grown-up).
  void _headSpace(Canvas canvas, _Geometry g, void Function() draw) {
    canvas.save();
    canvas.translate(50, _Geometry.chinY);
    canvas.scale(g.headScale);
    canvas.translate(-50, -_Geometry.chinY);
    draw();
    canvas.restore();
  }

  // ---------------------------------------------------------------- body --

  Path _deelPath(_Geometry g) {
    final sh = g.sh, bw = g.bw, hw = g.hw;
    return Path()
      ..moveTo(44, 46)
      ..lineTo(50 - sh + 3, 47.5)
      ..quadraticBezierTo(50 - sh, 48, 50 - sh, 52)
      ..cubicTo(50 - sh - 1, 60, 50 - bw, 62, 50 - bw, 71)
      ..cubicTo(50 - bw, 80, 50 - hw + 1, 90, 50 - hw, 100)
      ..lineTo(50 + hw, 100)
      ..cubicTo(50 + hw - 1, 90, 50 + bw, 80, 50 + bw, 71)
      ..cubicTo(50 + bw, 62, 50 + sh + 1, 60, 50 + sh, 52)
      ..quadraticBezierTo(50 + sh, 48, 50 + sh - 3, 47.5)
      ..lineTo(56, 46)
      ..close();
  }

  void _drawDeel(Canvas canvas, _Geometry g, ClothingItem deel) {
    final body = _deelPath(g);
    final bounds = body.getBounds();
    canvas.drawPath(body, _round(bounds, deel.color));

    canvas.save();
    canvas.clipPath(body);
    if (deel.pattern) _drawBrocade(canvas, bounds, deel.color, deel.accent);
    // Patterned hem border.
    canvas.drawRect(Rect.fromLTRB(0, 94.5, 100, 100), _fill(deel.accent));
    canvas.drawRect(Rect.fromLTRB(0, 94.5, 100, 95.3), _fill(_darken(deel.accent, 0.15)));
    final motif = _fill(_darken(deel.accent, 0.22));
    for (var x = 30.0; x < 72; x += 4) {
      final m = Path()
        ..moveTo(x, 97.3)
        ..lineTo(x + 1.3, 96.2)
        ..lineTo(x + 2.6, 97.3)
        ..lineTo(x + 1.3, 98.4)
        ..close();
      canvas.drawPath(m, motif);
    }
    canvas.restore();

    // Энгэр: the curved front panel edge, sweeping to the wearer's right
    // side and down to the hem.
    final lapel = Path()
      ..moveTo(54.5, 47)
      ..quadraticBezierTo(47, 56, 50 - g.sh + 3.5, 59)
      ..cubicTo(50 - g.bw + 2.5, 68, 50 - g.bw + 3, 86, 50 - g.hw + 4, 99);
    canvas.drawPath(lapel, _stroke(deel.accent, 2.6));
    canvas.drawPath(lapel, _stroke(_darken(deel.accent, 0.2), 0.35));

    for (final p in [
      const Offset(53, 49.5),
      const Offset(48, 54.5),
      Offset(50 - g.sh + 4.5, 59.5),
    ]) {
      canvas.drawCircle(p, 1.25, _sphere(p, 1.25, _gold));
    }
    canvas.drawPath(body, _stroke(_darken(deel.color, 0.3).withValues(alpha: 0.5), 0.4));
  }

  /// Round medallion brocade (like the patterned silk of a festive deel).
  void _drawBrocade(Canvas canvas, Rect bounds, Color base, Color accent) {
    final ring = _stroke(Color.lerp(base, accent, 0.45)!.withValues(alpha: 0.75), 0.45);
    final dot = _fill(Color.lerp(base, accent, 0.55)!.withValues(alpha: 0.8));
    var row = 0;
    for (var y = bounds.top + 6; y < 95; y += 9, row++) {
      for (var x = bounds.left + (row.isEven ? 3 : 8); x < bounds.right; x += 10) {
        final o = Offset(x, y);
        canvas.drawCircle(o, 3.1, ring);
        canvas.drawCircle(o, 1.5, ring);
        for (var k = 0; k < 4; k++) {
          final a = k * math.pi / 2 + math.pi / 4;
          canvas.drawCircle(o + Offset(math.cos(a), math.sin(a)) * 2.3, 0.45, dot);
        }
      }
    }
  }

  void _drawBelt(Canvas canvas, _Geometry g) {
    final belt = _item(ClothingSlot.belt);
    final color = belt?.color ?? _defaultBelt;
    final w = g.bw - 0.3;
    final band = RRect.fromLTRBR(50 - w, 67.5, 50 + w, 74, const Radius.circular(2));
    canvas.drawRRect(band, _round(band.outerRect, color));
    for (final y in [69.6, 71.8]) {
      canvas.drawLine(Offset(50 - w + 1.5, y), Offset(50 + w - 1.5, y),
          _stroke(_darken(color, 0.14).withValues(alpha: 0.7), 0.35));
    }
    // Knot and hanging tails on the wearer's left.
    final kx = 50 + w * 0.5;
    final dark = _darken(color, 0.12);
    final tails = Path()
      ..moveTo(kx - 1.6, 72.5)
      ..quadraticBezierTo(kx - 3, 80, kx - 2.2, 87)
      ..lineTo(kx + 1, 87)
      ..quadraticBezierTo(kx, 80, kx + 0.8, 72.5)
      ..moveTo(kx + 0.4, 72.5)
      ..quadraticBezierTo(kx + 3, 79, kx + 4.5, 84)
      ..lineTo(kx + 7, 83)
      ..quadraticBezierTo(kx + 4.5, 78, kx + 2.4, 72.5);
    canvas.drawPath(tails, _fill(dark));
    final knot = Rect.fromCenter(center: Offset(kx, 71), width: 5.2, height: 5.2);
    canvas.drawOval(knot, _sphere(knot.center, 2.6, color));
  }

  void _drawNeck(Canvas canvas) {
    final neck = const Rect.fromLTRB(46, 40, 54, 49);
    canvas.drawRect(neck, _round(neck, _skinShade));
  }

  void _drawStandCollar(Canvas canvas, Color trim) {
    final collar = Path()
      ..moveTo(44.2, 48.8)
      ..lineTo(44.8, 44.3)
      ..quadraticBezierTo(50, 46.4, 55.2, 44.3)
      ..lineTo(55.8, 48.8)
      ..quadraticBezierTo(50, 50.8, 44.2, 48.8)
      ..close();
    canvas.drawPath(collar, _round(collar.getBounds(), trim));
    const knot = Offset(54.3, 47.2);
    canvas.drawCircle(knot, 1.1, _sphere(knot, 1.1, _gold));
  }

  // -------------------------------------------------------- casual outfit --

  void _drawLegs(Canvas canvas, _Geometry g) {
    for (final side in [-1.0, 1.0]) {
      final x = 50 + side * g.legX;
      final top = Offset(x, 90);
      final bottom = Offset(x, 114);
      canvas.drawLine(top, bottom, _stroke(_skinShade, g.legW + 0.8));
      canvas.drawLine(top, bottom, _stroke(_skin, g.legW));
      canvas.drawLine(top + Offset(-g.legW * 0.18, 0), bottom + Offset(-g.legW * 0.18, 0),
          _stroke(_skinLight.withValues(alpha: 0.6), g.legW * 0.25));
    }
  }

  void _drawSneakers(Canvas canvas, _Geometry g) {
    final stripe = female ? _teeFemale : _teeMale;
    for (final side in [-1.0, 1.0]) {
      final x = 50 + side * g.legX;
      final shoe = Path()
        ..moveTo(x - 5, 121)
        ..lineTo(x - 5, 115.5)
        ..quadraticBezierTo(x - 4.6, 111.5, x, 111.5)
        ..quadraticBezierTo(x + 4.6, 111.5, x + 5, 115.5)
        ..lineTo(x + 5 + side * 1.5, 121)
        ..close();
      canvas.drawPath(shoe, _round(shoe.getBounds(), const Color(0xFFF4F4F2)));
      canvas.drawLine(Offset(x - 4.5, 117), Offset(x + 4.5, 117), _stroke(stripe, 1.1));
      canvas.drawRRect(
        RRect.fromLTRBR(x - 5.3, 120, x + 5.3 + side * 1.5, 122, const Radius.circular(1)),
        _fill(const Color(0xFFBDBDBD)),
      );
    }
  }

  Path _torsoPath(_Geometry g) {
    final sh = g.sh, bw = g.bw;
    return Path()
      ..moveTo(44, 46)
      ..lineTo(50 - sh + 3, 47.5)
      ..quadraticBezierTo(50 - sh, 48, 50 - sh, 52)
      ..cubicTo(50 - sh - 1, 60, 50 - bw, 62, 50 - bw, 71)
      ..cubicTo(50 - bw, 78, 50 - bw * 0.93, 82, 50 - bw * 0.88, 85)
      ..lineTo(50 + bw * 0.88, 85)
      ..cubicTo(50 + bw * 0.93, 82, 50 + bw, 78, 50 + bw, 71)
      ..cubicTo(50 + bw, 62, 50 + sh + 1, 60, 50 + sh, 52)
      ..quadraticBezierTo(50 + sh, 48, 50 + sh - 3, 47.5)
      ..lineTo(56, 46)
      ..close();
  }

  void _drawCasualTop(Canvas canvas, _Geometry g) {
    final tee = female ? _teeFemale : _teeMale;
    final shorts = female ? _shortsFemale : _shortsMale;
    final torso = _torsoPath(g);
    final bounds = torso.getBounds();

    // Skin underneath: only visible where the t-shirt doesn't reach. The
    // gradient is centered on the belly so it reads as round.
    final bellyRect = Rect.fromCenter(center: Offset(50, 76), width: g.bw * 2.1, height: 22);
    canvas.drawPath(torso, _skinPaint(bellyRect));

    // The t-shirt rides up over a round belly: its hem is highest in the
    // middle. `g.bellyShow` is 0 when fit (fully covered).
    final show = g.bellyShow;
    final hemSide = 83.0 - 9 * show;
    final hemMid = hemSide - 4.5 * show;
    canvas.save();
    canvas.clipPath(torso);
    final shirt = Path()
      ..moveTo(0, 40)
      ..lineTo(100, 40)
      ..lineTo(100, hemSide)
      ..quadraticBezierTo(50, 2 * hemMid - hemSide, 0, hemSide)
      ..close();
    canvas.drawPath(shirt, _round(bounds, tee));
    final hem = Path()
      ..moveTo(0, hemSide)
      ..quadraticBezierTo(50, 2 * hemMid - hemSide, 100, hemSide);
    canvas.drawPath(hem, _stroke(_darken(tee, 0.12), 1.2));
    // A little chest emblem: the "өлзий" endless knot, simplified.
    final emblem = Offset(50, 58);
    final ring = _stroke(Colors.white.withValues(alpha: 0.85), 0.55);
    canvas.drawCircle(emblem, 2.6, ring);
    canvas.drawRect(Rect.fromCenter(center: emblem, width: 2.4, height: 2.4), ring);
    canvas.restore();

    // Round neckline.
    canvas.drawArc(const Rect.fromLTRB(45.5, 43.2, 54.5, 49.2), 0.15, math.pi - 0.3, false,
        _stroke(_darken(tee, 0.12), 1.1));

    // Shorts.
    final ww = g.bw * 0.9 + 0.6;
    final s = Path()
      ..moveTo(50 - ww, 82)
      ..lineTo(50 + ww, 82)
      ..lineTo(50 + ww + 1.6, 96)
      ..lineTo(51.3, 96)
      ..lineTo(50, 89.5)
      ..lineTo(48.7, 96)
      ..lineTo(50 - ww - 1.6, 96)
      ..close();
    canvas.drawPath(s, _round(s.getBounds(), shorts));
    canvas.drawLine(Offset(50 - ww, 83.2), Offset(50 + ww, 83.2), _stroke(_darken(shorts, 0.12), 0.9));

    if (show > 0.05) {
      // The round belly hangs a little over the waistband.
      final overhang = Rect.fromCenter(center: const Offset(50, 80.2), width: g.bw * 1.75, height: 1 + 7 * show);
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, hemMid, 100, 90));
      canvas.drawOval(overhang, _skinPaint(bellyRect));
      canvas.drawArc(overhang, 0.35, math.pi - 0.7, false, _stroke(_skinShade.withValues(alpha: 0.8), 0.6));
      canvas.restore();
      final navel = Offset(50, (hemMid + overhang.bottom) / 2 + 0.8);
      canvas.drawArc(Rect.fromCenter(center: navel, width: 2.2, height: 1.6), 0.2, math.pi - 0.4, false,
          _stroke(_skinShade, 0.6));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(45.5, hemMid + 2.6), width: 9 * show, height: 2.6 * show),
        _fill(_skinLight.withValues(alpha: 0.6)),
      );
    }
  }

  // ---------------------------------------------------------------- arms --

  void _drawArms(Canvas canvas, _Geometry g,
      {required Color sleeve, required Color? cuff, required bool longSleeves}) {
    for (final side in [-1.0, 1.0]) {
      final shoulder = Offset(50 + side * (g.sh - 2.5), 52);
      final wrist = Offset(50 + side * (g.sh + g.armOut), 82);
      final hand = wrist + Offset(side * 0.4, 3);

      if (longSleeves) {
        canvas.drawLine(shoulder, wrist, _stroke(_darken(sleeve, 0.2), g.armW + 0.8));
        canvas.drawLine(shoulder, wrist, _stroke(sleeve, g.armW));
        canvas.drawLine(shoulder + Offset(-side * g.armW * 0.2, 0), wrist + Offset(-side * g.armW * 0.2, 0),
            _stroke(_lighten(sleeve, 0.08).withValues(alpha: 0.6), g.armW * 0.25));
        if (cuff != null) {
          canvas.drawLine(Offset.lerp(shoulder, wrist, 0.84)!, wrist, _stroke(cuff, g.armW + 0.4));
        }
      } else {
        // Bare arm with a short t-shirt sleeve.
        canvas.drawLine(shoulder, wrist, _stroke(_skinShade, g.armW * 0.82 + 0.6));
        canvas.drawLine(shoulder, wrist, _stroke(_skin, g.armW * 0.82));
        final sleeveEnd = Offset.lerp(shoulder, wrist, 0.36)!;
        canvas.drawLine(shoulder, sleeveEnd, _stroke(_darken(sleeve, 0.15), g.armW + 1.2));
        canvas.drawLine(shoulder, sleeveEnd, _stroke(sleeve, g.armW + 0.6));
      }
      final r = female ? 3.0 : 3.4;
      canvas.drawCircle(hand, r, _skinPaint(Rect.fromCircle(center: hand, radius: r)));
    }
  }

  // --------------------------------------------------------------- boots --

  void _drawBoots(Canvas canvas, {required bool legsVisible}) {
    final boots = _item(ClothingSlot.boots);
    final color = boots?.color ?? _defaultBoots;
    final accent = boots?.accent ?? _defaultBootsAccent;
    for (final side in [-1.0, 1.0]) {
      final x = 50 + side * 7;
      final top = legsVisible ? 101.0 : 96.0;
      // dx > 0 points outward, so the toes turn slightly away from each other.
      double px(double dx) => x + side * dx;
      final boot = Path()
        ..moveTo(px(-5), top)
        ..lineTo(px(5), top)
        ..lineTo(px(5), 112.5)
        ..cubicTo(px(8), 113, px(9.6), 115.5, px(9.3), 118.4)
        ..quadraticBezierTo(px(9), 121, px(6.5), 121)
        ..lineTo(px(-5), 121)
        ..close();
      canvas.drawPath(boot, _round(boot.getBounds(), color));
      canvas.drawRect(Rect.fromLTRB(x - 5, top, x + 5, top + 2), _fill(_darken(color, 0.12)));
      canvas.drawRect(Rect.fromLTRB(x - 5, 110.5, x + 5, 112), _fill(accent));
      final diamond = Path()
        ..moveTo(x, top + 4)
        ..lineTo(x + 2, top + 6.5)
        ..lineTo(x, top + 9)
        ..lineTo(x - 2, top + 6.5)
        ..close();
      canvas.drawPath(diamond, _fill(accent));
      canvas.drawLine(Offset(x - side * 5, 121), Offset(x + side * 4, 121), _stroke(_darken(color, 0.25), 1));
    }
  }

  // ---------------------------------------------------------------- head --

  void _drawBackHair(Canvas canvas, _Geometry g) {
    final fw = g.fw;
    final back = Path()
      ..moveTo(50 - fw / 2 - 2.5, 20)
      ..cubicTo(50 - fw * 0.66, 0, 50 + fw * 0.66, 0, 50 + fw / 2 + 2.5, 20)
      ..lineTo(50 + fw / 2 + 3.2, 55)
      ..quadraticBezierTo(50, 59, 50 - fw / 2 - 3.2, 55)
      ..close();
    canvas.drawPath(back, _hairPaint(back.getBounds()));
  }

  Paint _hairPaint(Rect r) => Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_hairLight, _hairDark, _hairDark],
      stops: [0, 0.45, 1],
    ).createShader(r);

  void _drawBraids(Canvas canvas, _Geometry g) {
    final fw = g.fw;
    for (final side in [-1.0, 1.0]) {
      final start = Offset(50 + side * (fw / 2 - 1.5), 35);
      final control = Offset(50 + side * (fw / 2 + 4), 54);
      final end = Offset(50 + side * (fw / 2 - 3.5), 80);
      final braid = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(braid, _stroke(_hairDark, 5));
      final plait = _stroke(_hairLight.withValues(alpha: 0.85), 0.5);
      for (var t = 0.06; t < 0.97; t += 0.085) {
        final p = _quad(start, control, end, t);
        final d = _quadTangent(start, control, end, t);
        final n = Offset(-d.dy, d.dx);
        final w = 2.3 - 0.5 * t;
        canvas.drawLine(p + n * w - d * 1.1, p + d * 0.5, plait);
        canvas.drawLine(p - n * w - d * 1.1, p + d * 0.5, plait);
      }
      final tie = end + const Offset(0, 2.6);
      canvas.drawOval(Rect.fromCenter(center: tie, width: 3.8, height: 2.2), _fill(const Color(0xFFC62828)));
      final tuft = Path()
        ..moveTo(end.dx - 1.5, end.dy + 3.4)
        ..quadraticBezierTo(end.dx, end.dy + 8, end.dx + 1.5, end.dy + 3.4)
        ..close();
      canvas.drawPath(tuft, _fill(_hairDark));
    }
  }

  Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  Offset _quadTangent(Offset a, Offset b, Offset c, double t) {
    final d = (b - a) * (2 * (1 - t)) + (c - b) * (2 * t);
    return d / d.distance;
  }

  void _drawHead(Canvas canvas, _Geometry g) {
    final c = g.c;
    final fw = g.fw;
    final s = fw / 40;
    final jaw = female ? 0.27 + 0.15 * c : 0.3 + 0.13 * c;

    for (final side in [-1.0, 1.0]) {
      final ear = Rect.fromCenter(center: Offset(50 + side * fw / 2, 28.5), width: 6, height: 9);
      canvas.drawOval(ear, _fill(_skin));
      canvas.drawArc(ear.deflate(1.5), side < 0 ? 1.2 : -1.9, 3.8, false, _stroke(_skinShade, 0.6));
    }

    final face = Path()
      ..moveTo(50, 4)
      ..cubicTo(50 + fw * 0.56, 4, 50 + fw / 2, 16, 50 + fw / 2, 26)
      ..cubicTo(50 + fw / 2, 36, 50 + fw * jaw, 42.5, 50, _Geometry.chinY)
      ..cubicTo(50 - fw * jaw, 42.5, 50 - fw / 2, 36, 50 - fw / 2, 26)
      ..cubicTo(50 - fw / 2, 16, 50 - fw * 0.56, 4, 50, 4)
      ..close();
    canvas.drawPath(face, _skinPaint(face.getBounds()));

    // Blush.
    for (final side in [-1.0, 1.0]) {
      final center = Offset(50 + side * fw * 0.3, 34);
      final r = (4.2 + 1.6 * c) * s;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFF08A8A).withValues(alpha: female ? 0.6 : 0.5),
            const Color(0xFFF08A8A).withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    // Big, glossy eyes: rounder and larger when chubby (cute), a little
    // narrower when fit (grown-up).
    final eyeY = 28.5;
    for (final side in [-1.0, 1.0]) {
      final center = Offset(50 + side * fw * 0.21, eyeY);
      final rx = 3.9 * s;
      final ry = (2.9 + 1.2 * c) * s;
      final sclera = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
      canvas.drawOval(sclera, _fill(const Color(0xFFFFFCF7)));
      canvas.save();
      canvas.clipPath(Path()..addOval(sclera));
      final irisC = center + Offset(-side * 0.25 * s, 0.25 * s);
      final ir = (2.75 + 0.35 * c) * s;
      canvas.drawCircle(
        irisC,
        ir,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, 0.3),
            colors: [_irisLight, _irisDark],
          ).createShader(Rect.fromCircle(center: irisC, radius: ir)),
      );
      canvas.drawCircle(irisC, 1.25 * s, _fill(const Color(0xFF140A04)));
      canvas.restore();
      canvas.drawCircle(center + Offset(-0.95 * s, -1.15 * s), 0.95 * s, _fill(Colors.white));
      canvas.drawCircle(center + Offset(1.1 * s, 1.0 * s), 0.45 * s, _fill(Colors.white.withValues(alpha: 0.9)));
      // Upper lid line.
      canvas.drawArc(sclera.inflate(0.2), math.pi + 0.12, math.pi - 0.24, false,
          _stroke(_lidInk, female ? 1.15 : 0.95));
      if (female) {
        final outer = Offset(center.dx + side * rx, center.dy - 0.4 * s);
        canvas.drawLine(outer, outer + Offset(side * 1.5 * s, -1.2 * s), _stroke(_lidInk, 0.7));
      }
    }

    // Eyebrows.
    final browY = eyeY - (5.6 + 0.6 * c) * s;
    for (final side in [-1.0, 1.0]) {
      final brow = Path()
        ..moveTo(50 + side * 3.4 * s, browY + 0.7)
        ..quadraticBezierTo(50 + side * 7.5 * s, browY - (female ? 1.6 : 1.0), 50 + side * 11.2 * s, browY + 0.5);
      canvas.drawPath(brow, _stroke(const Color(0xFF3A2618), female ? 0.9 : 1.55));
    }

    // Small soft nose.
    final nose = Path()
      ..moveTo(48.8, 34.6)
      ..quadraticBezierTo(50, 35.8, 51.2, 34.6);
    canvas.drawPath(nose, _stroke(_skinShade, 0.75));
    canvas.drawCircle(const Offset(50, 32.6), 0.7, _fill(_skinLight.withValues(alpha: 0.8)));

    // Gentle closed smile.
    if (female) {
      final lips = Path()
        ..moveTo(47.6, 38.3)
        ..quadraticBezierTo(50, 40.6, 52.4, 38.3)
        ..quadraticBezierTo(50, 39.1, 47.6, 38.3)
        ..close();
      canvas.drawPath(lips, _fill(const Color(0xFFD96C7C)));
    } else {
      final mouth = Path()
        ..moveTo(47.2, 38.2)
        ..quadraticBezierTo(50, 40.4, 52.8, 38.2);
      canvas.drawPath(mouth, _stroke(const Color(0xFFA0503C), 0.85));
    }

    if (female) {
      _drawFemaleFrontHair(canvas, fw);
      for (final side in [-1.0, 1.0]) {
        final p = Offset(50 + side * (fw / 2 + 0.3), 33.2);
        canvas.drawCircle(p, 1.2, _sphere(p, 1.2, _gold));
        canvas.drawCircle(p + const Offset(0, 2), 0.9, _sphere(p + const Offset(0, 2), 0.9, const Color(0xFFE57373)));
      }
    } else {
      _drawMaleHair(canvas, fw);
    }
  }

  void _drawMaleHair(Canvas canvas, double fw) {
    final hair = Path()
      ..moveTo(50 - fw / 2 - 0.8, 27)
      ..cubicTo(50 - fw * 0.62, 7, 50 - fw * 0.36, 0.2, 52, 0.6)
      ..cubicTo(50 + fw * 0.42, 1, 50 + fw * 0.62, 8, 50 + fw / 2 + 0.8, 27)
      ..quadraticBezierTo(50 + fw / 2 - 1.2, 19, 50 + fw / 2 - 3.5, 15.5)
      ..quadraticBezierTo(56, 14.5, 46, 11.2)
      ..quadraticBezierTo(41, 14.2, 50 - fw / 2 + 2.5, 16.5)
      ..quadraticBezierTo(50 - fw / 2 + 0.5, 20, 50 - fw / 2 - 0.8, 27)
      ..close();
    canvas.drawPath(hair, _hairPaint(hair.getBounds()));
    final shine = Path()
      ..moveTo(50 - fw * 0.3, 5)
      ..quadraticBezierTo(50 - fw * 0.05, 2.2, 50 + fw * 0.2, 3.6);
    canvas.drawPath(shine, _stroke(_hairLight.withValues(alpha: 0.9), 1.1));
  }

  void _drawFemaleFrontHair(Canvas canvas, double fw) {
    final hair = Path()
      ..moveTo(50 - fw / 2 - 1, 31)
      ..cubicTo(50 - fw * 0.64, 7, 50 - fw * 0.36, 0.5, 50, 0.8)
      ..cubicTo(50 + fw * 0.36, 0.5, 50 + fw * 0.64, 7, 50 + fw / 2 + 1, 31)
      ..quadraticBezierTo(50 + fw / 2 - 1.5, 19, 50 + fw * 0.28, 12.5)
      ..quadraticBezierTo(53.5, 9, 50, 7.5)
      ..quadraticBezierTo(46.5, 9, 50 - fw * 0.28, 12.5)
      ..quadraticBezierTo(50 - fw / 2 + 1.5, 19, 50 - fw / 2 - 1, 31)
      ..close();
    canvas.drawPath(hair, _hairPaint(hair.getBounds()));
    final shine = Path()
      ..moveTo(50 - fw * 0.32, 5.5)
      ..quadraticBezierTo(50 - fw * 0.15, 2.8, 48, 2.8);
    canvas.drawPath(shine, _stroke(_hairLight, 1.0));
  }

  // ---------------------------------------------------------------- hats --

  void _drawHat(Canvas canvas, ClothingItem hat) {
    switch (hat.hatStyle) {
      case HatStyle.toortsog:
        _drawFlaredBrim(canvas, _darken(hat.color, 0.04), top: 3, bottom: 14);
        _drawDome(canvas, _lighten(hat.color, 0.04), base: 3.5, height: 12, halfWidth: 19);
        final tassel = _stroke(hat.accent.withValues(alpha: 0.9), 0.6);
        for (final dx in [-8.0, -4.0, 0.0, 4.0, 8.0]) {
          canvas.drawLine(const Offset(50, -7), Offset(50 + dx, 2), tassel);
        }
        const knob = Offset(50, -8.4);
        canvas.drawCircle(knob, 2.3, _sphere(knob, 2.3, hat.accent));
      case HatStyle.loovuuz:
        _drawDome(canvas, hat.color, base: 4, height: 13, halfWidth: 17);
        final gold = _stroke(_gold.withValues(alpha: 0.8), 0.5);
        for (final dx in [-9.0, 0.0, 9.0]) {
          canvas.drawLine(Offset(50 + dx * 0.4, -6), Offset(50 + dx, 3), gold);
        }
        const knob = Offset(50, -8.6);
        canvas.drawCircle(knob, 1.9, _sphere(knob, 1.9, _gold));
        // Fluffy fur rim.
        final fur = hat.accent;
        final rim = RRect.fromLTRBR(25, 1.5, 75, 15.5, const Radius.circular(7));
        canvas.drawRRect(
          rim,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_lighten(fur, 0.12), fur, _darken(fur, 0.12)],
            ).createShader(rim.outerRect),
        );
        for (var x = 27.0; x <= 73; x += 3.3) {
          canvas.drawCircle(Offset(x, 2.2), 2.1, _fill(_lighten(fur, 0.1)));
          canvas.drawCircle(Offset(x + 1.6, 15), 2.0, _fill(_darken(fur, 0.08)));
        }
        final strands = _stroke(_darken(fur, 0.15).withValues(alpha: 0.6), 0.4);
        for (var x = 28.0; x < 72; x += 2.4) {
          canvas.drawLine(Offset(x, 5), Offset(x + 0.8, 12), strands);
        }
      case HatStyle.janjin:
        _drawFlaredBrim(canvas, hat.accent, top: 4, bottom: 14, flare: 3.5);
        _drawDome(canvas, hat.color, base: 4.5, height: 12.5, halfWidth: 17);
        final dots = _fill(_darken(hat.color, 0.12));
        for (final p in [const Offset(42, -1), const Offset(50, -3.5), const Offset(58, -1), const Offset(46, 2), const Offset(54, 2)]) {
          canvas.drawCircle(p, 0.9, dots);
        }
        canvas.drawLine(const Offset(50, -7), const Offset(50, -14), _stroke(_darken(hat.color, 0.1), 1.4));
        const bead = Offset(50, -7.8);
        canvas.drawCircle(bead, 1.5, _sphere(bead, 1.5, const Color(0xFFC62828)));
        const top = Offset(50, -14.5);
        canvas.drawCircle(top, 1.9, _sphere(top, 1.9, hat.color));
      case null:
        break;
    }
  }

  /// A brim band that widens upward (the upturned brim of a Mongolian hat).
  void _drawFlaredBrim(Canvas canvas, Color color, {required double top, required double bottom, double flare = 2.5}) {
    final brim = Path()
      ..moveTo(28, bottom)
      ..lineTo(72, bottom)
      ..lineTo(72 + flare, top)
      ..lineTo(28 - flare, top)
      ..close();
    canvas.drawPath(brim, _round(brim.getBounds(), color));
    canvas.drawOval(Rect.fromCenter(center: Offset(50, top), width: 44 + flare * 2, height: 3.2),
        _fill(_darken(color, 0.12)));
    canvas.drawLine(Offset(28, bottom), Offset(72, bottom), _stroke(_darken(color, 0.18), 0.6));
  }

  void _drawDome(Canvas canvas, Color color, {required double base, required double height, required double halfWidth}) {
    final dome = Path()
      ..moveTo(50 - halfWidth, base)
      ..cubicTo(50 - halfWidth, base - height * 1.3, 50 + halfWidth, base - height * 1.3, 50 + halfWidth, base)
      ..close();
    canvas.drawPath(
      dome,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 0.9,
          colors: [_lighten(color, 0.14), color, _darken(color, 0.16)],
        ).createShader(dome.getBounds()),
    );
  }

  // --------------------------------------------------------- accessories --

  void _drawKhadag(Canvas canvas, ClothingItem item) {
    for (final side in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(50 + side * 5, 46)
        ..quadraticBezierTo(50 + side * 8.5, 60, 50 + side * 7.5, 80);
      canvas.drawPath(path, _stroke(_darken(item.color, 0.1), 5));
      canvas.drawPath(path, _stroke(item.color, 4.2));
      canvas.drawPath(path, _stroke(item.accent.withValues(alpha: 0.7), 0.5));
      for (final dx in [-1.5, 0.0, 1.5]) {
        canvas.drawLine(Offset(50 + side * 7.5 + dx, 82), Offset(50 + side * 7.5 + dx, 85), _stroke(item.color, 0.5));
      }
    }
  }

  void _drawMedal(Canvas canvas, ClothingItem item) {
    final ribbon = Path()
      ..moveTo(46.5, 47)
      ..lineTo(50, 57)
      ..lineTo(53.5, 47);
    canvas.drawPath(ribbon, _stroke(item.accent, 2.3));
    const center = Offset(50, 60.5);
    canvas.drawCircle(center, 4, _sphere(center, 4, item.color));
    canvas.drawCircle(center, 2.3, _stroke(_darken(item.color, 0.18), 0.5));
  }

  void _drawQuiverBack(Canvas canvas, ClothingItem item) {
    // Arrows poking up over the left shoulder, then the quiver body.
    for (var i = 0; i < 3; i++) {
      final base = Offset(36 + i * 2.4, 48);
      final tip = Offset(29 + i * 2.6, 30 - i * 0.8);
      canvas.drawLine(base, tip, _stroke(const Color(0xFF8D6E4C), 0.8));
      final fletch = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - 1.6, tip.dy + 3.6)
        ..lineTo(tip.dx + 0.4, tip.dy + 3.2)
        ..lineTo(tip.dx + 1.8, tip.dy + 3.8)
        ..close();
      canvas.drawPath(fletch, _fill(item.accent));
    }
    final quiver = Path()
      ..moveTo(31, 38)
      ..lineTo(39, 37)
      ..lineTo(45, 80)
      ..lineTo(38, 81)
      ..close();
    canvas.drawPath(quiver, _round(quiver.getBounds(), item.color));
    canvas.drawLine(const Offset(31, 38), const Offset(39, 37), _stroke(_gold, 1.2));
  }

  void _drawQuiverStrap(Canvas canvas, _Geometry g, ClothingItem item) {
    canvas.drawLine(Offset(50 - g.sh + 4, 50), Offset(50 + g.bw - 3, 76), _stroke(_darken(item.color, 0.05), 2));
  }

  String get _equippedSignature => ClothingSlot.values.map((s) => equipped[s] ?? '-').join('|');

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) {
    return oldDelegate.chubbiness != chubbiness ||
        oldDelegate.female != female ||
        oldDelegate._equippedSignature != _equippedSignature;
  }
}

/// Body measurements (in the 100-wide unit space) derived from chubbiness.
class _Geometry {
  static const chinY = 44.0;

  final double c;
  final bool female;

  _Geometry(this.c, this.female);

  double get _bodyScale => 0.76 + 0.36 * c;

  /// Shoulder half-width.
  double get sh => 15.5 * _bodyScale * (female ? 0.92 : 1.0);

  /// Belly half-width.
  double get bw => (female ? 12.0 : 13.0) * _bodyScale + 12 * c;

  /// Deel hem half-width.
  double get hw => 17 * _bodyScale * (female ? 1.08 : 1.0);

  /// Big head when chubby (cute), smaller when fit (grown-up).
  double get headScale => 0.94 + 0.12 * c;

  /// Face width.
  double get fw => (37 + 5 * c) * (female ? 0.96 : 1.0);

  double get armW => 8.5 * (0.85 + 0.2 * c) * (female ? 0.9 : 1.0);

  /// How far the wrists sit outside the shoulders (arms rest on the belly).
  double get armOut => 4 + 6 * c;

  double get legW => 7.8 * (0.85 + 0.3 * c) * (female ? 0.92 : 1.0);
  double get legX => 5.2 + 2.2 * c;

  /// 0..1: how much of the boy's belly shows under the t-shirt.
  double get bellyShow => female ? 0 : ((c - 0.35) / 0.65).clamp(0.0, 1.0);
}
