import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/items.dart';
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  SizedBox(
                    height: 200,
                    child: FittedBox(
                      child: CharacterWidget(
                        level: game.level,
                        gender: game.gender,
                        equipped: game.equipped,
                        height: 300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Зах', style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Дээл, малгай, цамц, гутал, бүс — бүх түвшинд таарна.', style: text.bodyMedium),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => watchAdForCoins(context),
                          icon: const Icon(Icons.play_circle_fill),
                          label: const Text('+$kCoinsPerAdWatch зоос'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final slot in ItemSlot.values) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Text(slot.label, style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (slot != ItemSlot.deel && game.equipped[ItemSlot.deel] != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '· дээл өмссөн үед харагдахгүй',
                          style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: slot == ItemSlot.deel ? 0.56 : 0.8,
                ),
                delegate: SliverChildListDelegate([
                  for (final item in shopCatalog.where((i) => i.slot == slot)) _ItemCard(item: item),
                ]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ShopItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final owned = game.owned.contains(item.id);
    final wearing = game.isWearing(item);

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
              child: item.slot == ItemSlot.deel
                  // Deels are shown on the character at the current level.
                  ? FittedBox(
                      child: CharacterWidget(
                        level: game.level,
                        gender: game.gender,
                        equipped: {ItemSlot.deel: item.id},
                        height: 300,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(item.icon(game.gender), fit: BoxFit.contain),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: !owned
                  ? FilledButton.icon(
                      onPressed: game.coins >= item.price
                          ? () {
                              game.buy(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${item.name} худалдаж авлаа!')),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.monetization_on, size: 16),
                      label: Text('${item.price}'),
                    )
                  : wearing
                      ? FilledButton.tonalIcon(
                          onPressed: () => game.toggleWear(item),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Тайлах'),
                        )
                      : OutlinedButton(
                          onPressed: () => game.toggleWear(item),
                          child: const Text('Өмсөх'),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
