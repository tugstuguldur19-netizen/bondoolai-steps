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

  /// Brocade medallion pattern woven into the fabric (deels).
  final bool pattern;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.price,
    required this.color,
    required this.accent,
    this.hatStyle,
    this.accessoryStyle,
    this.pattern = false,
  });
}

const List<ClothingItem> shopCatalog = [
  // Малгай
  ClothingItem(
    id: 'hat_toortsog',
    name: 'Тоорцог',
    slot: ClothingSlot.hat,
    price: 60,
    color: Color(0xFF2342A6),
    accent: Color(0xFFC62828),
    hatStyle: HatStyle.toortsog,
  ),
  ClothingItem(
    id: 'hat_loovuuz',
    name: 'Үнэгэн лоовууз',
    slot: ClothingSlot.hat,
    price: 120,
    color: Color(0xFF7B1E2E),
    accent: Color(0xFFA89684),
    hatStyle: HatStyle.loovuuz,
  ),
  ClothingItem(
    id: 'hat_janjin',
    name: 'Жанжин малгай',
    slot: ClothingSlot.hat,
    price: 250,
    color: Color(0xFFC9A33A),
    accent: Color(0xFF4E3322),
    hatStyle: HatStyle.janjin,
  ),
  // Дээл
  ClothingItem(
    id: 'deel_blue',
    name: 'Хөх дээл',
    slot: ClothingSlot.deel,
    price: 100,
    color: Color(0xFF2553B8),
    accent: Color(0xFFD9A441),
    pattern: true,
  ),
  ClothingItem(
    id: 'deel_red',
    name: 'Улаан дээл',
    slot: ClothingSlot.deel,
    price: 100,
    color: Color(0xFF86202F),
    accent: Color(0xFFD9A441),
    pattern: true,
  ),
  ClothingItem(
    id: 'deel_green',
    name: 'Ногоон торгон дээл',
    slot: ClothingSlot.deel,
    price: 150,
    color: Color(0xFF2E7D4F),
    accent: Color(0xFFF0DFA8),
  ),
  ClothingItem(
    id: 'deel_gold',
    name: 'Алтан торгон дээл',
    slot: ClothingSlot.deel,
    price: 300,
    color: Color(0xFFD6A82E),
    accent: Color(0xFF1F4FA8),
    pattern: true,
  ),
  // Бүс
  ClothingItem(
    id: 'belt_orange',
    name: 'Улбар шар бүс',
    slot: ClothingSlot.belt,
    price: 40,
    color: Color(0xFFE8832A),
    accent: Color(0xFFE8832A),
  ),
  ClothingItem(
    id: 'belt_yellow',
    name: 'Шар торгон бүс',
    slot: ClothingSlot.belt,
    price: 60,
    color: Color(0xFFE3BC55),
    accent: Color(0xFFE3BC55),
  ),
  ClothingItem(
    id: 'belt_blue',
    name: 'Цэнхэр бүс',
    slot: ClothingSlot.belt,
    price: 40,
    color: Color(0xFF4F86C6),
    accent: Color(0xFF4F86C6),
  ),
  // Гутал
  ClothingItem(
    id: 'boots_black',
    name: 'Хар гутал',
    slot: ClothingSlot.boots,
    price: 70,
    color: Color(0xFF2A2522),
    accent: Color(0xFF6B5B4E),
  ),
  ClothingItem(
    id: 'boots_red',
    name: 'Хээтэй улаан гутал',
    slot: ClothingSlot.boots,
    price: 120,
    color: Color(0xFFA3262A),
    accent: Color(0xFFE0B040),
  ),
  // Чимэглэл
  ClothingItem(
    id: 'acc_khadag',
    name: 'Цэнхэр хадаг',
    slot: ClothingSlot.accessory,
    price: 80,
    color: Color(0xFF8FD3F4),
    accent: Color(0xFFD6F0FB),
    accessoryStyle: AccessoryStyle.khadag,
  ),
  ClothingItem(
    id: 'acc_medal',
    name: 'Аваргын медаль',
    slot: ClothingSlot.accessory,
    price: 150,
    color: Color(0xFFE0B43A),
    accent: Color(0xFFC62828),
    accessoryStyle: AccessoryStyle.medal,
  ),
  ClothingItem(
    id: 'acc_bow',
    name: 'Нум сум',
    slot: ClothingSlot.accessory,
    price: 200,
    color: Color(0xFF7A4B2A),
    accent: Color(0xFFEFE6D6),
    accessoryStyle: AccessoryStyle.bow,
  ),
];

ClothingItem? itemById(String id) {
  for (final item in shopCatalog) {
    if (item.id == id) return item;
  }
  return null;
}
