import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/items.dart';
import '../state/app_state.dart';

final Map<String, Future<ui.Image>> _imageCache = {};
Future<Map<String, List<int>>>? _layerOffsets;

Future<ui.Image> _loadImage(String asset) => _imageCache.putIfAbsent(asset, () async {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    });

Future<Map<String, List<int>>> _loadOffsets() => _layerOffsets ??= () async {
      final raw = jsonDecode(await rootBundle.loadString('assets/layers/layers.json')) as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, (v as List).cast<int>()));
    }();

/// Layers are drawn in this order over the base body.
const _layerOrder = [ItemSlot.shoes, ItemSlot.top, ItemSlot.belt, ItemSlot.hat];

/// How much wider the body is at each level than at level 1 (measured on the
/// base illustrations); used to widen deels, which only exist at one size.
const Map<Gender, List<double>> _levelWidth = {
  Gender.male: [1.0, 1.034, 1.079, 1.213, 1.371, 1.607],
  Gender.female: [1.0, 1.011, 1.044, 1.189, 1.344, 1.6],
};

class _Layer {
  final ui.Image image;
  final Offset offset;
  const _Layer(this.image, this.offset);
}

class _Look {
  final ui.Image body;
  final bool isDeel;
  final List<_Layer> layers;
  const _Look(this.body, this.isDeel, this.layers);
}

/// Бондоолой at a body [level] (1 = fit … 6 = obese) wearing [equipped].
class CharacterWidget extends StatelessWidget {
  final int level;
  final Gender gender;
  final Map<ItemSlot, String> equipped;
  final double height;

  const CharacterWidget({
    super.key,
    required this.level,
    required this.gender,
    this.equipped = const {},
    this.height = 420,
  });

  /// All character images share one 520x680 canvas.
  static const double canvasWidth = 520;
  static const double canvasHeight = 680;

  Future<_Look> _load() async {
    final deel = equipped[ItemSlot.deel];
    if (deel != null) {
      return _Look(await _loadImage(deelAsset(gender, deel)), true, const []);
    }
    final offsets = await _loadOffsets();
    final body = await _loadImage(baseAsset(gender, level));
    final layers = <_Layer>[];
    for (final slot in _layerOrder) {
      final id = equipped[slot];
      if (id == null) continue;
      final key = layerKey(gender, level, id);
      final offset = offsets[key];
      if (offset == null) continue;
      final image = await _loadImage('assets/layers/$key.png');
      layers.add(_Layer(image, Offset(offset[0].toDouble(), offset[1].toDouble())));
    }
    return _Look(body, false, layers);
  }

  @override
  Widget build(BuildContext context) {
    final width = height * canvasWidth / canvasHeight;
    final signature = '${gender.name}/$level/${ItemSlot.values.map((s) => equipped[s] ?? '-').join(',')}';
    return SizedBox(
      width: width,
      height: height,
      child: FutureBuilder<_Look>(
        key: ValueKey(signature),
        future: _load(),
        builder: (context, snap) {
          final look = snap.data;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: look == null
                ? const SizedBox.expand()
                : CustomPaint(
                    key: ValueKey(signature),
                    size: Size(width, height),
                    painter: _LookPainter(
                      look,
                      look.isDeel ? _levelWidth[gender]![level.clamp(1, 6) - 1] : 1.0,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _LookPainter extends CustomPainter {
  final _Look look;

  /// Belly widening for deels (1.0 = as drawn).
  final double widen;

  _LookPainter(this.look, this.widen);

  /// Share of the widening applied at a given height (0 = top of canvas):
  /// full at the belly, a little at the head and feet.
  static double _profile(double y) => 0.12 + 0.88 * math.exp(-math.pow((y - 0.66) / 0.19, 2));

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / CharacterWidget.canvasWidth;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    final body = look.body;
    final iw = body.width.toDouble();
    final ih = body.height.toDouble();

    if (widen <= 1.001) {
      canvas.drawImageRect(body, Rect.fromLTWH(0, 0, iw, ih), Offset.zero & size, paint);
    } else {
      // Thin horizontal strips, each stretched by the belly profile.
      const strips = 170;
      final srcStep = ih / strips;
      final dstStep = size.height / strips;
      final cx = size.width / 2;
      for (var i = 0; i < strips; i++) {
        final k = 1 + (widen - 1) * _profile((i + 0.5) / strips);
        final w = size.width * k;
        canvas.drawImageRect(
          body,
          Rect.fromLTWH(0, i * srcStep, iw, srcStep),
          Rect.fromLTWH(cx - w / 2, i * dstStep, w, dstStep + 0.6),
          paint,
        );
      }
    }

    for (final layer in look.layers) {
      final img = layer.image;
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(layer.offset.dx * scale, layer.offset.dy * scale, img.width * scale, img.height * scale),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LookPainter old) => old.look != look || old.widen != widen;
}
