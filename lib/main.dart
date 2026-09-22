import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  final appState = GameState();
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const BondoolaiApp(),
    ),
  );
}

class BondoolaiApp extends StatelessWidget {
  const BondoolaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Бондоолой',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF64B5F6)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
