import 'package:flutter/material.dart';

enum ClothingSlot { hat, top, bottom, shoes, glasses }

class ClothingItem {
  final String id;
  final String name;
  final ClothingSlot slot;
  final int price;
  final Color color;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.price,
    required this.color,
  });
}

const List<ClothingItem> shopCatalog = [
  ClothingItem(
    id: 'hat_red',
    name: 'Улаан малгай',
    slot: ClothingSlot.hat,
    price: 50,
    color: Colors.redAccent,
  ),
  ClothingItem(
    id: 'hat_blue',
    name: 'Хөх малгай',
    slot: ClothingSlot.hat,
    price: 50,
    color: Colors.blueAccent,
  ),
  ClothingItem(
    id: 'hat_gold',
    name: 'Алтан малгай',
    slot: ClothingSlot.hat,
    price: 200,
    color: Color(0xFFFFC107),
  ),
  ClothingItem(
    id: 'top_green',
    name: 'Ногоон цамц',
    slot: ClothingSlot.top,
    price: 80,
    color: Colors.green,
  ),
  ClothingItem(
    id: 'top_orange',
    name: 'Улбар шар цамц',
    slot: ClothingSlot.top,
    price: 80,
    color: Colors.deepOrange,
  ),
  ClothingItem(
    id: 'top_purple',
    name: 'Ягаан цамц',
    slot: ClothingSlot.top,
    price: 120,
    color: Colors.purple,
  ),
  ClothingItem(
    id: 'bottom_black',
    name: 'Хар өмд',
    slot: ClothingSlot.bottom,
    price: 60,
    color: Color(0xFF212121),
  ),
  ClothingItem(
    id: 'bottom_navy',
    name: 'Нил ягаан өмд',
    slot: ClothingSlot.bottom,
    price: 60,
    color: Color(0xFF283593),
  ),
  ClothingItem(
    id: 'shoes_white',
    name: 'Цагаан гутал',
    slot: ClothingSlot.shoes,
    price: 40,
    color: Colors.white,
  ),
  ClothingItem(
    id: 'shoes_red',
    name: 'Улаан гутал',
    slot: ClothingSlot.shoes,
    price: 70,
    color: Colors.red,
  ),
  ClothingItem(
    id: 'glasses_black',
    name: 'Хар нүдний шил',
    slot: ClothingSlot.glasses,
    price: 90,
    color: Color(0xFF212121),
  ),
  ClothingItem(
    id: 'glasses_gold',
    name: 'Алтан шилтэй нүдний шил',
    slot: ClothingSlot.glasses,
    price: 250,
    color: Color(0xFFFFD54F),
  ),
];

ClothingItem itemById(String id) =>
    shopCatalog.firstWhere((e) => e.id == id);
