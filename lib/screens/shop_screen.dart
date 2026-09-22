import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/clothing_item.dart';
import '../state/app_state.dart';

String _slotLabel(ClothingSlot slot) {
  switch (slot) {
    case ClothingSlot.hat:
      return 'Малгай';
    case ClothingSlot.top:
      return 'Цамц';
    case ClothingSlot.bottom:
      return 'Өмд';
    case ClothingSlot.shoes:
      return 'Гутал';
    case ClothingSlot.glasses:
      return 'Нүдний шил';
  }
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дэлгүүр'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${app.coins}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: shopCatalog.length,
        itemBuilder: (context, index) {
          final item = shopCatalog[index];
          final owned = app.owned.contains(item.id);
          final equipped = app.equipped[item.slot] == item.id;

          return Card(
            elevation: equipped ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: equipped
                  ? const BorderSide(color: Colors.green, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _slotLabel(item.slot),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  if (!owned)
                    FilledButton.icon(
                      onPressed: app.coins >= item.price
                          ? () => app.buyItem(item)
                          : null,
                      icon: const Icon(Icons.monetization_on, size: 16),
                      label: Text('${item.price}'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => app.toggleEquip(item),
                      child: Text(equipped ? 'Тайлах' : 'Өмсөх'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
