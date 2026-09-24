import 'package:flutter/material.dart';

enum ClothingSlot { hat, deel, belt, boots, accessory }

enum HatStyle { toortsog, loovuuz, janjin }

enum AccessoryStyle { khadag, medal, bow }

String slotLabel(ClothingSlot slot) {
  switch (slot) {
    case ClothingSlot.hat:
      return 'Малгай';
    case ClothingSlot.deel:
      return 'Дээл';
    case ClothingSlot.belt:
      return 'Бүс';
    case ClothingSlot.boots:
      return 'Гутал';
    case ClothingSlot.accessory:
      return 'Чимэглэл';
  }
}

class ClothingItem {
  final String id;
  final String name;
  final ClothingSlot slot;
  final int price;

  /// Main fabric color.
  final Color color;

  /// Trim / accent color (deel lapel and cuffs, hat tassel, boot pattern).
  final Color accent;

  final HatStyle? hatStyle;
  final AccessoryStyle? accessoryStyle;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.price,
    required this.color,
    required this.accent,
    this.hatStyle,
    this.accessoryStyle,
  });
}

const List<ClothingItem> shopCatalog = [
  // Малгай
  ClothingItem(
    id: 'hat_toortsog',
    name: 'Тоорцог',
    slot: ClothingSlot.hat,
    price: 60,
    color: Color(0xFF1E3A8A),
    accent: Color(0xFFD32F2F),
    hatStyle: HatStyle.toortsog,
  ),
  ClothingItem(
    id: 'hat_loovuuz',
    name: 'Үнэгэн лоовууз',
    slot: ClothingSlot.hat,
    price: 120,
    color: Color(0xFFB71C1C),
    accent: Color(0xFFA1683A),
    hatStyle: HatStyle.loovuuz,
  ),
  ClothingItem(
    id: 'hat_janjin',
    name: 'Жанжин малгай',
    slot: ClothingSlot.hat,
    price: 250,
    color: Color(0xFFC9A227),
    accent: Color(0xFFD32F2F),
    hatStyle: HatStyle.janjin,
  ),
  // Дээл
  ClothingItem(
    id: 'deel_blue',
    name: 'Хөх дээл',
    slot: ClothingSlot.deel,
    price: 100,
    color: Color(0xFF1565C0),
    accent: Color(0xFFE0B040),
  ),
  ClothingItem(
    id: 'deel_red',
    name: 'Улаан дээл',
    slot: ClothingSlot.deel,
    price: 100,
    color: Color(0xFFB3261E),
    accent: Color(0xFF212121),
  ),
  ClothingItem(
    id: 'deel_green',
    name: 'Ногоон торгон дээл',
    slot: ClothingSlot.deel,
    price: 150,
    color: Color(0xFF2E7D32),
    accent: Color(0xFFF5E6B8),
  ),
  ClothingItem(
    id: 'deel_gold',
    name: 'Алтан торгон дээл',
    slot: ClothingSlot.deel,
    price: 300,
    color: Color(0xFFD4A017),
    accent: Color(0xFF0D47A1),
  ),
  // Бүс
  ClothingItem(
    id: 'belt_orange',
    name: 'Улбар шар бүс',
    slot: ClothingSlot.belt,
    price: 40,
    color: Color(0xFFEF6C00),
    accent: Color(0xFFEF6C00),
  ),
  ClothingItem(
    id: 'belt_yellow',
    name: 'Шар торгон бүс',
    slot: ClothingSlot.belt,
    price: 60,
    color: Color(0xFFFBC02D),
    accent: Color(0xFFFBC02D),
  ),
  ClothingItem(
    id: 'belt_blue',
    name: 'Цэнхэр бүс',
    slot: ClothingSlot.belt,
    price: 40,
    color: Color(0xFF29B6F6),
    accent: Color(0xFF29B6F6),
  ),
  // Гутал
  ClothingItem(
    id: 'boots_black',
    name: 'Хар гутал',
    slot: ClothingSlot.boots,
    price: 70,
    color: Color(0xFF212121),
    accent: Color(0xFF8D6E63),
  ),
  ClothingItem(
    id: 'boots_red',
    name: 'Хээтэй улаан гутал',
    slot: ClothingSlot.boots,
    price: 120,
    color: Color(0xFFB71C1C),
    accent: Color(0xFFFFD54F),
  ),
  // Чимэглэл
  ClothingItem(
    id: 'acc_khadag',
    name: 'Цэнхэр хадаг',
    slot: ClothingSlot.accessory,
    price: 80,
    color: Color(0xFF4FC3F7),
    accent: Color(0xFFB3E5FC),
    accessoryStyle: AccessoryStyle.khadag,
  ),
  ClothingItem(
    id: 'acc_medal',
    name: 'Аваргын медаль',
    slot: ClothingSlot.accessory,
    price: 150,
    color: Color(0xFFFFC107),
    accent: Color(0xFFD32F2F),
    accessoryStyle: AccessoryStyle.medal,
  ),
  ClothingItem(
    id: 'acc_bow',
    name: 'Нум сум',
    slot: ClothingSlot.accessory,
    price: 200,
    color: Color(0xFF6D4C41),
    accent: Color(0xFFD7CCC8),
    accessoryStyle: AccessoryStyle.bow,
  ),
];

ClothingItem? itemById(String id) {
  for (final item in shopCatalog) {
    if (item.id == id) return item;
  }
  return null;
}
