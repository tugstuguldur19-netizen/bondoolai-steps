import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/outfit.dart';
import '../state/app_state.dart';

final Map<String, Future<ui.Image>> _imageCache = {};

Future<ui.Image> _loadImage(String asset) => _imageCache.putIfAbsent(asset, () async {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    });

/// Бондоолой, drawn from the character illustrations. While chubby, the
/// belly area of the picture is widened; it eases back to the original
/// illustration as the day's goal is reached.
class CharacterWidget extends StatelessWidget {
  /// 1.0 = chubbiest (no steps yet), 0.15 = fit.
  final double chubbiness;
  final String outfitId;
  final Gender gender;
  final double height;

  const CharacterWidget({
    super.key,
    required this.chubbiness,
    required this.outfitId,
    required this.gender,
    this.height = 420,
  });

  /// Source illustration aspect (width / height) and the extra width
  /// reserved for the widest (chubbiest) belly.
  static const double _imageAspect = 380 / 980;
  static const double _maxStretch = 1.4;

  @override
  Widget build(BuildContext context) {
    final width = height * _imageAspect * _maxStretch;
    final asset = outfitById(outfitId).asset(gender);
    return SizedBox(
      width: width,
      height: height,
      child: FutureBuilder<ui.Image>(
        future: _loadImage(asset),
        builder: (context, snap) {
          final image = snap.data;
          if (image == null) return const SizedBox.shrink();
          final amount = ((chubbiness - 0.15) / 0.85).clamp(0.0, 1.0);
          return TweenAnimationBuilder<double>(
            tween: Tween(end: amount),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, a, _) => CustomPaint(
              painter: _ChubbyPainter(image, a),
            ),
          );
        },
      ),
    );
  }
}

class _ChubbyPainter extends CustomPainter {
  final ui.Image image;

  /// 0 = original illustration, 1 = chubbiest.
  final double amount;

  _ChubbyPainter(this.image, this.amount);

  /// Extra width per height: most at the belly, a little for the head
  /// (rounder cheeks), almost none at the feet.
  static double _profile(double y) => 0.05 + 0.33 * math.exp(-math.pow((y - 0.58) / 0.13, 2));

  @override
  void paint(Canvas canvas, Size size) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final scale = size.height / ih;
    final baseW = iw * scale;
    final cx = size.width / 2;
    final paint = Paint()..filterQuality = FilterQuality.medium;

    if (amount <= 0.001) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, iw, ih),
        Rect.fromLTWH(cx - baseW / 2, 0, baseW, size.height),
        paint,
      );
      return;
    }

    // Draw the illustration in thin horizontal strips, each stretched by the
    // belly profile, so the widening is smooth from head to feet.
    const strips = 140;
    final srcStep = ih / strips;
    final dstStep = size.height / strips;
    for (var i = 0; i < strips; i++) {
      final k = 1 + amount * _profile((i + 0.5) / strips);
      final w = baseW * k;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, i * srcStep, iw, srcStep),
        // Slight overlap hides hairline seams between strips.
        Rect.fromLTWH(cx - w / 2, i * dstStep, w, dstStep + 0.6),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChubbyPainter old) => old.image != image || old.amount != amount;
}
