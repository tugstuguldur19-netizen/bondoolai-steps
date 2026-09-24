import '../state/app_state.dart';

/// A complete look for Бондоолой. Each outfit is a finished character
/// illustration per gender, e.g. assets/characters/boy_blue.png.
class Outfit {
  final String id;
  final String name;
  final String details;
  final int price;

  const Outfit({
    required this.id,
    required this.name,
    required this.details,
    required this.price,
  });

  String asset(Gender gender) =>
      'assets/characters/${gender == Gender.female ? 'girl' : 'boy'}_$id.png';
}

const String defaultOutfitId = 'default';

const List<Outfit> outfitCatalog = [
  Outfit(
    id: defaultOutfitId,
    name: 'Энгийн дээл',
    details: 'Анхны хувцас',
    price: 0,
  ),
  Outfit(
    id: 'blue',
    name: 'Хөх торгон дээл',
    details: 'Тоорцог малгай, аваргын медаль',
    price: 150,
  ),
  Outfit(
    id: 'red',
    name: 'Улаан торгон дээл',
    details: 'Үнэгэн лоовууз малгай',
    price: 250,
  ),
  Outfit(
    id: 'gold',
    name: 'Алтан торгон дээл',
    details: 'Жанжин малгай, нум сум',
    price: 400,
  ),
];

Outfit outfitById(String id) =>
    outfitCatalog.firstWhere((o) => o.id == id, orElse: () => outfitCatalog.first);
