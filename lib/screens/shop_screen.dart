import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/clothing_item.dart';
import '../state/app_state.dart';
import '../widgets/character_painter.dart';
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
                    height: 170,
                    child: FittedBox(
                      child: CharacterWidget(
                        chubbiness: game.chubbiness,
                        equipped: game.equipped,
                        gender: game.gender,
                        size: 120,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Монгол хувцас', style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Зоосоороо Бондоолойдоо гоё хувцас аваарай.',
                          style: text.bodyMedium,
                        ),
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
          for (final slot in ClothingSlot.values) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(slotLabel(slot), style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
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
  final ClothingItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final scheme = Theme.of(context).colorScheme;
    final owned = game.owned.contains(item.id);
    final wearing = game.equipped[item.slot] == item.id;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: wearing ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
                border: Border.all(color: item.accent, width: 5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (wearing)
              Text('Өмссөн', style: TextStyle(color: scheme.primary, fontSize: 12)),
            if (item.slot == ClothingSlot.belt && game.equipped[ClothingSlot.deel] == null)
              Text(
                'Дээлтэй хамт харагдана',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            const Spacer(),
            if (!owned)
              FilledButton.icon(
                onPressed: game.coins >= item.price
                    ? () {
                        game.buyItem(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.name} худалдаж авлаа!')),
                        );
                      }
                    : null,
                icon: const Icon(Icons.monetization_on, size: 16),
                label: Text('${item.price}'),
              )
            else
              OutlinedButton(
                onPressed: () => game.toggleEquip(item),
                child: Text(wearing ? 'Тайлах' : 'Өмсөх'),
              ),
          ],
        ),
      ),
    );
  }
}
