import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'screens/root_screen.dart';
import 'state/ad_service.dart';
import 'state/app_state.dart';
import 'state/social_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  final game = GameState();
  await game.init();
  final social = SocialState(game);
  await social.init();
  final ads = AdService()..preload();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: game),
        ChangeNotifierProvider.value(value: social),
        Provider.value(value: ads),
      ],
      child: const BondoolaiApp(),
    ),
  );
}

class BondoolaiApp extends StatelessWidget {
  const BondoolaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0), brightness: b),
          useMaterial3: true,
        );

    return MaterialApp(
      title: 'Бондоолой',
      debugShowCheckedModeBanner: false,
      locale: const Locale('mn'),
      supportedLocales: const [Locale('mn')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const RootScreen(),
    );
  }
}
