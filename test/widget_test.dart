import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('Health Connect steps merge with the phone sensor (higher wins)', (tester) async {
    const channel = MethodChannel('bondoolai/health');
    final today = todayKey();
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'status':
          return 'available';
        case 'hasPermission':
          return true;
        case 'dailySteps':
          return {today: 4321, yesterday: 12000};
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    final game = GameState();
    expect(game.todaySteps, 0);
    expect(await game.connectHealth(), isNull);
    expect(game.healthConnected, isTrue);
    expect(game.todaySteps, 4321);
    expect(game.history[yesterday], 12000);

    await game.disconnectHealth();
    expect(game.healthConnected, isFalse);
    expect(game.todaySteps, 0);
  });

  testWidgets('steps counted by the background service show up in the app', (tester) async {
    const channel = MethodChannel('bondoolai/steps');
    final today = todayKey();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'snapshot') return {today: 5000};
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    final game = GameState();
    expect(game.todaySteps, 0);
    await game.syncSteps();
    expect(game.todaySteps, 5000);
    expect(game.history[today], 5000);
  });
}
