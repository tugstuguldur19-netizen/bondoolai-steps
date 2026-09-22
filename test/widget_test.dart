import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bondoolai_steps/main.dart';
import 'package:bondoolai_steps/state/app_state.dart';

void main() {
  testWidgets('Home screen shows the step goal', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<GameState>.value(
        value: GameState(),
        child: const BondoolaiApp(),
      ),
    );
    await tester.pump();

    expect(find.textContaining('10000'), findsOneWidget);
  });
}
