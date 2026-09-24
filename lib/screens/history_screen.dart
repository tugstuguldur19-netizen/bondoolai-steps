import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/step_history_chart.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final history = game.history;
    final goal = game.goal;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last30 = [
      for (var i = 29; i >= 0; i--)
        () {
          final d = DateTime(today.year, today.month, today.day - i);
          return DaySteps(d, history[dayKey(d)] ?? 0);
        }(),
    ];

    final records = history.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    final activeDays = last30.where((d) => d.steps > 0).toList();
    final total30 = last30.fold<int>(0, (s, d) => s + d.steps);
    final avg = activeDays.isEmpty ? 0 : total30 ~/ activeDays.length;
    final best = records.isEmpty
        ? null
        : records.reduce((a, b) => b.value > a.value ? b : a);

    // Streak of goal-reaching days ending today (or yesterday, if today's
    // goal isn't reached yet).
    var streak = 0;
    var cursor = (history[dayKey(today)] ?? 0) >= goal
        ? today
        : DateTime(today.year, today.month, today.day - 1);
    while ((history[dayKey(cursor)] ?? 0) >= goal) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Түүх')),
      body: records.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Одоогоор бүртгэл алга.\nАлхаж эхлээрэй!',
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.9,
                  children: [
                    _StatTile(
                      label: 'Дээд амжилт',
                      value: formatNumber(best!.value),
                      sub: shortDate(DateTime.parse(best.key)),
                      icon: Icons.emoji_events,
                    ),
                    _StatTile(
                      label: 'Өдрийн дундаж',
                      value: formatNumber(avg),
                      sub: 'сүүлийн 30 хоног',
                      icon: Icons.timeline,
                    ),
                    _StatTile(
                      label: 'Нийт алхам',
                      value: formatNumber(total30),
                      sub: 'сүүлийн 30 хоног',
                      icon: Icons.directions_walk,
                    ),
                    _StatTile(
                      label: 'Цуврал',
                      value: '$streak өдөр',
                      sub: 'зорилгоо дараалан биелүүлсэн',
                      icon: Icons.local_fire_department,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Сүүлийн 30 хоног', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                StepHistoryChart(days: last30, goal: goal),
                const SizedBox(height: 24),
                Text('Өдөр бүрийн бүртгэл', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                for (final r in records)
                  _RecordRow(
                    day: DateTime.parse(r.key),
                    steps: r.value,
                    goal: goal,
                    isToday: r.key == dayKey(today),
                    isBest: best.key == r.key,
                  ),
              ],
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;

  const _StatTile({required this.label, required this.value, required this.sub, required this.icon});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(label, style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final DateTime day;
  final int steps;
  final int goal;
  final bool isToday;
  final bool isBest;

  const _RecordRow({
    required this.day,
    required this.steps,
    required this.goal,
    required this.isToday,
    required this.isBest,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final reached = steps >= goal;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        reached ? Icons.check_circle : Icons.radio_button_unchecked,
        color: reached ? Colors.green.shade600 : scheme.outline,
      ),
      title: Text(isToday ? 'Өнөөдөр' : longDate(day)),
      subtitle: Text(
        [
          if (reached) 'Зорилго биелсэн',
          if (isBest) 'Дээд амжилт',
        ].join(' · '),
      ),
      trailing: Text(
        '${formatNumber(steps)} алхам',
        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
