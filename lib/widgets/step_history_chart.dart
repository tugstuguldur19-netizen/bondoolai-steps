import 'package:flutter/material.dart';

import '../util/format.dart';

class DaySteps {
  final DateTime day;
  final int steps;
  const DaySteps(this.day, this.steps);
}

/// Daily step bars (oldest -> newest) with a dashed goal line.
/// Tap a bar to see its date and value.
class StepHistoryChart extends StatefulWidget {
  final List<DaySteps> days;
  final int goal;

  const StepHistoryChart({super.key, required this.days, required this.goal});

  @override
  State<StepHistoryChart> createState() => _StepHistoryChartState();
}

class _StepHistoryChartState extends State<StepHistoryChart> {
  int? _selected;

  void _select(Offset local, double width) {
    if (widget.days.isEmpty) return;
    final slot = width / widget.days.length;
    final i = (local.dx / slot).floor().clamp(0, widget.days.length - 1);
    setState(() => _selected = _selected == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final days = widget.days;
    final selected = _selected != null && _selected! < days.length ? days[_selected!] : null;
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 22,
          child: Text(
            selected == null
                ? 'Баганан дээр дарж дэлгэрэнгүйг харна уу'
                : '${shortDate(selected.day)} ${weekdayName(selected.day)} · '
                    '${formatNumber(selected.steps)} алхам',
            style: selected == null
                ? muted
                : text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _select(d.localPosition, constraints.maxWidth),
            child: CustomPaint(
              size: Size(constraints.maxWidth, 160),
              painter: _BarsPainter(
                days: days,
                goal: widget.goal,
                selected: _selected,
                bar: scheme.primary,
                grid: scheme.outlineVariant,
                goalColor: scheme.onSurfaceVariant,
                labelStyle: muted ?? const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (days.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(shortDate(days.first.day), style: muted),
              Text(shortDate(days[days.length ~/ 2].day), style: muted),
              Text('Өнөөдөр', style: muted),
            ],
          ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<DaySteps> days;
  final int goal;
  final int? selected;
  final Color bar;
  final Color grid;
  final Color goalColor;
  final TextStyle labelStyle;

  _BarsPainter({
    required this.days,
    required this.goal,
    required this.selected,
    required this.bar,
    required this.grid,
    required this.goalColor,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    const topPad = 14.0;
    final chartH = size.height - topPad;
    final maxSteps = days.map((d) => d.steps).fold<int>(goal, (a, b) => a > b ? a : b);
    final maxV = maxSteps <= 0 ? 1.0 : maxSteps * 1.08;
    double yFor(num v) => topPad + chartH - chartH * (v / maxV);

    // Baseline.
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );

    final slot = size.width / days.length;
    const gap = 2.0;
    final barW = (slot - gap).clamp(1.0, 18.0);
    for (var i = 0; i < days.length; i++) {
      final v = days[i].steps;
      if (v <= 0) continue;
      final x = i * slot + (slot - barW) / 2;
      final top = yFor(v);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(x, top, x + barW, size.height - 1),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final dimmed = selected != null && selected != i;
      canvas.drawRRect(rect, Paint()..color = dimmed ? bar.withValues(alpha: 0.35) : bar);
    }

    // Dashed goal line with a label.
    final gy = yFor(goal);
    final dash = Paint()
      ..color = goalColor
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, gy), Offset((x + 4).clamp(0, size.width), gy), dash);
    }
    final tp = TextPainter(
      text: TextSpan(text: 'Зорилго ${formatNumber(goal)}', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width, gy - tp.height - 2));
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.days != days || old.goal != goal || old.selected != selected || old.bar != bar;
}
