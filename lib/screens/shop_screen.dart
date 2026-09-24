import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/outfit.dart';
import '../state/app_state.dart';
import '../widgets/character.dart';
import 'home_screen.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дэлгүүр'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${game.coins}', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Монгол хувцас', style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Зоосоороо Бондоолойдоо гоё дээл аваарай.', style: text.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: () => watchAdForCoins(context),
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('+$kCoinsPerAdWatch'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.52,
            children: [for (final o in outfitCatalog) _OutfitCard(outfit: o)],
          ),
        ],
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final Outfit outfit;
  const _OutfitCard({required this.outfit});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final owned = game.owned.contains(outfit.id);
    final wearing = game.outfitId == outfit.id;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: wearing ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          children: [
            Expanded(
              child: FittedBox(
                child: CharacterWidget(
                  chubbiness: game.chubbiness,
                  outfitId: outfit.id,
                  gender: game.gender,
                  height: 300,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              outfit.name,
              textAlign: TextAlign.center,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              outfit.details,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: wearing
                  ? FilledButton.tonalIcon(
                      onPressed: null,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Өмссөн'),
                    )
                  : owned
                      ? OutlinedButton(
                          onPressed: () => game.wearOutfit(outfit),
                          child: const Text('Өмсөх'),
                        )
                      : FilledButton.icon(
                          onPressed: game.coins >= outfit.price
                              ? () {
                                  game.buyOutfit(outfit);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${outfit.name} худалдаж авлаа!')),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.monetization_on, size: 16),
                          label: Text('${outfit.price}'),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
