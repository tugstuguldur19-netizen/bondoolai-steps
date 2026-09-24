import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../state/ad_service.dart';
import '../state/app_state.dart';
import '../util/format.dart';
import '../widgets/character_painter.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from system settings: pick up a newly granted permission.
    if (state != AppLifecycleState.resumed) return;
    final game = context.read<GameState>();
    if (!game.permissionDenied) return;
    Permission.activityRecognition.status.then((s) {
      if (s.isGranted) game.startTracking();
    });
  }

  Future<void> _fixPermission() async {
    final game = context.read<GameState>();
    final status = await Permission.activityRecognition.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await game.startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final percent = (game.progress * 100).round();
    final isGirl = game.gender == Gender.female;

    final String cheer;
    if (game.progress >= 1) {
      cheer = 'Гайхалтай! Өнөөдрийн зорилго биеллээ!';
    } else if (game.progress >= 0.7) {
      cheer = 'Бараг хүрлээ, жаахан үлдлээ!';
    } else if (game.progress >= 0.3) {
      cheer = 'Сайн байна, үргэлжлүүлээрэй!';
    } else {
      cheer = isGirl ? 'Алхвал Бондоолой хөөрхөн болно!' : 'Алхвал Бондоолой царайлаг болно!';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бондоолой'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${game.coins}', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
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
            if (game.permissionDenied)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Алхам тоолохын тулд "Биеийн хөдөлгөөн" зөвшөөрөл хэрэгтэй.',
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                    TextButton(onPressed: _fixPermission, child: const Text('Зөвшөөрөх')),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: FittedBox(
                  child: CharacterWidget(
                    chubbiness: game.chubbiness,
                    equipped: game.equipped,
                    gender: game.gender,
                  ),
                ),
              ),
            ),
            Text(cheer, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: game.progress,
                  minHeight: 14,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
            Text(
              '${formatNumber(game.todaySteps)} / ${formatNumber(game.goal)} алхам ($percent%)',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const _WatchAdButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _WatchAdButton extends StatelessWidget {
  const _WatchAdButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => watchAdForCoins(context),
      icon: const Icon(Icons.play_circle_fill),
      label: const Text('Зар үзээд +$kCoinsPerAdWatch зоос авах'),
    );
  }
}

Future<void> watchAdForCoins(BuildContext context) async {
  final game = context.read<GameState>();
  final ads = context.read<AdService>();
  final messenger = ScaffoldMessenger.of(context);
  final started = await ads.show(onReward: game.addCoinsFromAd);
  if (!started) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Зар ачаалж байна, түр хүлээгээд дахин оролдоно уу.')),
    );
  }
}
