import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../util/format.dart';
import 'gender_picker_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final goal = context.read<GameState>().goal;
    _controller = TextEditingController(text: goal.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Зөв тоо оруулна уу.')),
      );
      return;
    }
    context.read<GameState>().setGoal(value);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Өдрийн зорилго ${formatNumber(value)} алхам боллоо.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Тохиргоо')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Дүр', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const GenderChoice(compact: true),
          const SizedBox(height: 28),
          const _HealthSection(),
          const SizedBox(height: 28),
          Text('Өдрийн алхамын зорилго', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Анхны утга: ${formatNumber(kDefaultGoal)} алхам',
            style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Алхамын тоо',
              suffixText: 'алхам',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [5000, 8000, 10000, 12000, 15000, 20000].map((v) {
              return ActionChip(
                label: Text(formatNumber(v)),
                onPressed: () => _controller.text = v.toString(),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Хадгалах'),
            ),
          ),
        ],
      ),
    );
  }
}


class _HealthSection extends StatefulWidget {
  const _HealthSection();

  @override
  State<_HealthSection> createState() => _HealthSectionState();
}

class _HealthSectionState extends State<_HealthSection> {
  bool _busy = false;

  Future<void> _connect() async {
    final game = context.read<GameState>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final error = await game.connectHealth();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(
      content: Text(error ?? 'Samsung Health-ийн алхамын мэдээлэл холбогдлоо!'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final synced = game.healthSyncedAt;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Samsung Health', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (game.healthConnected)
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text('Холбогдсон', style: text.labelLarge?.copyWith(color: Colors.green.shade700)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              game.healthConnected
                  ? 'Samsung Health апп хаалттай үед ч алхмыг тань тоолдог. '
                      'Бондоолой түүний өдөр бүрийн алхамыг Health Connect-оор уншина.'
                  : 'Samsung Health-ийн алхамыг холбовол апп хаалттай байсан үеийн '
                      'алхам ч тоологдож, илүү нарийвчлалтай болно.',
              style: text.bodyMedium,
            ),
            if (game.healthConnected && synced != null) ...[
              const SizedBox(height: 4),
              Text(
                'Сүүлд шинэчилсэн: ${synced.hour.toString().padLeft(2, '0')}:${synced.minute.toString().padLeft(2, '0')}',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            if (game.healthConnected)
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: game.refreshHealth,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Шинэчлэх'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: game.disconnectHealth, child: const Text('Салгах')),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _busy ? null : _connect,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.link),
                label: const Text('Samsung Health холбох'),
              ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Алхам харагдахгүй байвал', style: text.labelLarge),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '1. Samsung Health апп-ыг нээнэ.\n'
                  '2. Тохиргоо → Health Connect руу орно.\n'
                  '3. Samsung Health-д "Алхам" мэдээллийг Health Connect руу бичих зөвшөөрөл өгнө.\n'
                  '4. Бондоолой руу буцаж ирээд "Шинэчлэх" дарна.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
