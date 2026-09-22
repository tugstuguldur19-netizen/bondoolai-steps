import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/ad_service.dart';
import '../state/app_state.dart';
import '../widgets/character_painter.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _adService.preload();
  }

  void _watchAd() async {
    final app = context.read<GameState>();
    final started = await _adService.show(
      onReward: () {
        app.addCoinsFromAd();
      },
    );
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Зар бэлдэж байна, дахин оролдоно уу…')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<GameState>();
    final percent = (app.progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бондоолой'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checkroom),
            tooltip: 'Дэлгүүр',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShopScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Тохиргоо',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${app.coins}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _watchAd,
                    icon: const Icon(Icons.play_circle_fill, size: 18),
                    label: Text('+$kCoinsPerAdWatch зоос'),
                  ),
                ],
              ),
            ),
            if (app.permissionDenied)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'Алхам тоолохын тулд "Идэвхийн танигч" зөвшөөрлийг '
                  'тохиргооноос идэвхжүүлнэ үү.',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
            Expanded(
              child: Center(
                child: CharacterWidget(
                  chubbiness: app.chubbiness,
                  equipped: app.equipped,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: app.progress,
                      minHeight: 14,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${app.todaySteps} / ${app.goal} алхам ($percent%)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
