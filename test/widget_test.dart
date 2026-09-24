import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bondoolai_steps/main.dart';
import 'package:bondoolai_steps/state/ad_service.dart';
import 'package:bondoolai_steps/state/app_state.dart';
import 'package:bondoolai_steps/state/social_state.dart';
import 'package:bondoolai_steps/util/format.dart';

Widget _app(GameState game) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider(create: (_) => SocialState(game)),
        Provider.value(value: AdService()),
      ],
      child: const BondoolaiApp(),
    );

void main() {
  testWidgets('first launch asks for a character, then shows home', (tester) async {
    final game = GameState();
    await tester.pumpWidget(_app(game));
    await tester.pumpAndSettle();

    expect(find.text('Дүрээ сонгоно уу'), findsOneWidget);
    await tester.tap(find.text('Охин'));
    await tester.pumpAndSettle();

    expect(game.gender, Gender.female);
    expect(find.textContaining('10,000 алхам'), findsOneWidget);
    expect(find.text('Найзууд'), findsOneWidget);
  });

  testWidgets('every tab renders without errors', (tester) async {
    final game = GameState();
    await game.setGender(Gender.male);
    await tester.pumpWidget(_app(game));
    await tester.pumpAndSettle();

    for (final tab in ['Найзууд', 'Түүх', 'Дэлгүүр', 'Нүүр']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
    }
    expect(find.text('Бондоолой'), findsWidgets);
  });

  test('formatNumber groups thousands', () {
    expect(formatNumber(0), '0');
    expect(formatNumber(999), '999');
    expect(formatNumber(10000), '10,000');
    expect(formatNumber(1234567), '1,234,567');
  });
}
