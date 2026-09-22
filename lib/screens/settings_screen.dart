import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final goal = context.read<GameState>().goal;
    _controller = TextEditingController(text: goal.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text.trim());
    if (value != null && value > 0) {
      context.read<GameState>().setGoal(value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Зорилго $value алхам болголоо')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тохиргоо')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Өдрийн алхамын зорилго',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Анхдагч утга: 10,000 алхам',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Алхамын тоо',
                suffixText: 'алхам',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [5000, 8000, 10000, 12000, 15000, 20000].map((v) {
                return ActionChip(
                  label: Text('$v'),
                  onPressed: () {
                    _controller.text = v.toString();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Хадгалах'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
