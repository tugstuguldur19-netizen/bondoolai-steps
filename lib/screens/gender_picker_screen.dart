import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/character_painter.dart';

/// Shown on first launch before anything else.
class GenderPickerScreen extends StatelessWidget {
  const GenderPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text('Бондоолой', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Дүрээ сонгоно уу', style: text.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Алхах тусам таны дүр туранхай, гоё болно!',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              const Expanded(child: GenderChoice()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two side-by-side character cards; tapping one selects that gender.
class GenderChoice extends StatelessWidget {
  final bool compact;
  const GenderChoice({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in Gender.values) ...[
          if (g != Gender.values.first) const SizedBox(width: 12),
          Expanded(
            child: _GenderCard(
              gender: g,
              selected: game.genderChosen && game.gender == g,
              compact: compact,
              onTap: () => game.setGender(g),
            ),
          ),
        ],
      ],
    );
  }
}

class _GenderCard extends StatelessWidget {
  final Gender gender;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _GenderCard({
    required this.gender,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMale = gender == Gender.male;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? scheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: compact ? 120 : 220,
                child: FittedBox(
                  child: CharacterWidget(
                    chubbiness: 1.0,
                    equipped: const {},
                    gender: gender,
                    size: 160,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_circle, size: 18, color: scheme.primary),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    isMale ? 'Хүү' : 'Охин',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (!compact)
                Text(
                  isMale ? 'Алхвал царайлаг болно' : 'Алхвал хөөрхөн болно',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
