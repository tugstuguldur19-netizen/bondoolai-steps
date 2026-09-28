import '../state/app_state.dart';

/// Where an item is worn. A deel is a complete traditional outfit (with its
/// own hat and boots); the other slots dress the everyday look (t-shirt and
/// shorts/skirt) and are hidden while a deel is worn.
enum ItemSlot { deel, hat, top, shoes, belt }

extension ItemSlotInfo on ItemSlot {
  String get label {
    switch (this) {
      case ItemSlot.deel:
        return 'Дээл';
      case ItemSlot.hat:
        return 'Малгай';
      case ItemSlot.top:
        return 'Цамц';
      case ItemSlot.shoes:
        return 'Гутал';
      case ItemSlot.belt:
        return 'Бүс';
    }
  }
}

class ShopItem {
  final String id;
  final String name;
  final ItemSlot slot;
  final int price;

  const ShopItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.price,
  });

  /// Picture for the shop card.
  String icon(Gender gender) => slot == ItemSlot.deel
      ? deelAsset(gender, id)
      : 'assets/items/$id.png';
}

String baseAsset(Gender gender, int level) =>
    'assets/characters/${_g(gender)}_level$level.png';

String deelAsset(Gender gender, String id) =>
    'assets/characters/${_g(gender)}_deel_$id.png';

/// Item layer fitted to one body level (see assets/layers/layers.json).
String layerKey(Gender gender, int level, String itemId) => '${_g(gender)}_${level}_$itemId';

String _g(Gender gender) => gender == Gender.female ? 'girl' : 'boy';

const List<ShopItem> shopCatalog = [
  ShopItem(id: 'kazakh', name: 'Казах дээл', slot: ItemSlot.deel, price: 300),
  ShopItem(id: 'buriad', name: 'Буриад дээл', slot: ItemSlot.deel, price: 350),
  ShopItem(id: 'khalkh', name: 'Халх дээл', slot: ItemSlot.deel, price: 350),
  ShopItem(id: 'torgon', name: 'Торгон дээл', slot: ItemSlot.deel, price: 500),
  ShopItem(id: 'hat_loovuuz', name: 'Үнэгэн лоовууз', slot: ItemSlot.hat, price: 150),
  ShopItem(id: 'hat_toortsog', name: 'Тоорцог малгай', slot: ItemSlot.hat, price: 120),
  ShopItem(id: 'hat_janjin', name: 'Жанжин малгай', slot: ItemSlot.hat, price: 200),
  ShopItem(id: 'hat_khatan', name: 'Хатан малгай', slot: ItemSlot.hat, price: 250),
  ShopItem(id: 'top_cashmere', name: 'Ноолууран цамц', slot: ItemSlot.top, price: 200),
  ShopItem(id: 'top_hoodie_navy', name: 'Соёмботой худи (хөх)', slot: ItemSlot.top, price: 180),
  ShopItem(id: 'top_hoodie_gray', name: 'Соёмботой худи (саарал)', slot: ItemSlot.top, price: 180),
  ShopItem(id: 'shoes_running', name: 'Гүйлтийн пүүз', slot: ItemSlot.shoes, price: 100),
  ShopItem(id: 'shoes_wings', name: 'Далавчтай пүүз', slot: ItemSlot.shoes, price: 400),
  ShopItem(id: 'belt_champion', name: 'Аваргын бүс', slot: ItemSlot.belt, price: 500),
];

ShopItem? itemById(String id) {
  for (final item in shopCatalog) {
    if (item.id == id) return item;
  }
  return null;
}

/// Outfits from earlier versions, mapped to the matching new deel.
const Map<String, String> legacyOutfitIds = {
  'blue': 'buriad',
  'red': 'khalkh',
  'gold': 'torgon',
};
