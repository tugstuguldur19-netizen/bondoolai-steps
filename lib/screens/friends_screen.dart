import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/share.dart';
import '../state/social_state.dart';
import '../util/format.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  LeaderboardPeriod _period = LeaderboardPeriod.day;

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialState>();

    Widget body;
    if (!social.configured) {
      body = const _Message(
        icon: Icons.cloud_off,
        title: 'Найзуудын функц одоогоор идэвхжээгүй байна',
        text: 'Сервер тохируулагдсаны дараа найзуудтайгаа өрсөлдөх боломжтой болно.',
      );
    } else if (!social.hasProfile) {
      body = const _NameSetup();
    } else {
      body = RefreshIndicator(
        onRefresh: social.refreshLeaderboards,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _MyCodeCard(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Тэргүүлэгчид',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (social.busy)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<LeaderboardPeriod>(
              segments: [
                for (final p in LeaderboardPeriod.values)
                  ButtonSegment(value: p, label: Text(p.label)),
              ],
              selected: {_period},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
            const SizedBox(height: 12),
            if (social.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  social.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            _Leaderboard(entries: social.board(_period)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Найзууд'),
        actions: [
          if (social.configured && social.hasProfile) ...[
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Найз нэмэх',
              onPressed: () => _showAddFriend(context),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Нэр солих',
              onPressed: () => _showRename(context, social.name ?? ''),
            ),
          ],
        ],
      ),
      body: body,
    );
  }
}

Future<void> _showAddFriend(BuildContext context) async {
  final social = context.read<SocialState>();
  final messenger = ScaffoldMessenger.of(context);
  final code = await showDialog<String>(
    context: context,
    builder: (_) => const _TextPromptDialog(
      title: 'Найз нэмэх',
      label: 'Найзын 6 оронтой код',
      action: 'Нэмэх',
      maxLength: 6,
      uppercase: true,
    ),
  );
  if (code == null || code.trim().isEmpty) return;
  try {
    final name = await social.addFriend(code);
    messenger.showSnackBar(SnackBar(content: Text('$name таны найз боллоо!')));
  } on SocialException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

Future<void> _showRename(BuildContext context, String current) async {
  final social = context.read<SocialState>();
  final messenger = ScaffoldMessenger.of(context);
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: 'Нэр солих',
      label: 'Таны нэр',
      action: 'Хадгалах',
      initial: current,
      maxLength: 30,
    ),
  );
  if (name == null || name.trim().isEmpty) return;
  try {
    await social.saveName(name);
  } on SocialException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

class _NameSetup extends StatefulWidget {
  const _NameSetup();

  @override
  State<_NameSetup> createState() => _NameSetupState();
}

class _NameSetupState extends State<_NameSetup> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    try {
      await context.read<SocialState>().saveName(_controller.text);
    } on SocialException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<SocialState>().busy;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.groups, size: 64),
        const SizedBox(height: 12),
        Text(
          'Найзуудтайгаа өрсөлдөөрэй!',
          textAlign: TextAlign.center,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Найзууддаа харагдах нэрээ оруулна уу.',
          textAlign: TextAlign.center,
          style: text.bodyMedium,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Таны нэр',
            errorText: _error,
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: busy ? null : _submit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Эхлэх'),
          ),
        ),
      ],
    );
  }
}

class _MyCodeCard extends StatelessWidget {
  const _MyCodeCard();

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialState>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final code = social.friendCode ?? '';

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Сайн байна уу, ${social.name}!', style: text.titleMedium?.copyWith(color: scheme.onPrimaryContainer)),
            const SizedBox(height: 8),
            Text('Миний найзын код', style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer)),
            SelectableText(
              code,
              style: text.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final shared = await shareText(social.inviteText);
                      if (!shared) {
                        messenger.showSnackBar(const SnackBar(content: Text('Урилгыг хуулж авлаа.')));
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Урих'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Кодыг хуулж авлаа.')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Хуулах'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _showAddFriend(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Найзын кодоор нэмэх'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  final List<LeaderboardEntry>? entries;
  const _Leaderboard({required this.entries});

  static const _medalColors = [Color(0xFFD4A017), Color(0xFF9E9E9E), Color(0xFFB0703C)];

  @override
  Widget build(BuildContext context) {
    final list = entries;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (list == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < list.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: list[i].isMe ? scheme.secondaryContainer : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: SizedBox(
                width: 40,
                child: i < 3
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.emoji_events, color: _medalColors[i], size: 34),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    : Center(child: Text('${i + 1}', style: text.titleMedium)),
              ),
              title: Text(
                list[i].isMe ? '${list[i].name} (Та)' : list[i].name,
                style: TextStyle(fontWeight: list[i].isMe ? FontWeight.bold : FontWeight.normal),
              ),
              trailing: Text(
                '${formatNumber(list[i].steps)} алхам',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        if (list.length <= 1)
          const _Message(
            icon: Icons.person_add_alt_1,
            title: 'Одоогоор найз алга',
            text: '"Урих" товчийг дарж найзуудаа урьж, тэдний кодыг оруулж нэмээрэй.',
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Message({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _TextPromptDialog extends StatefulWidget {
  final String title;
  final String label;
  final String action;
  final String initial;
  final int maxLength;
  final bool uppercase;

  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.action,
    this.initial = '',
    required this.maxLength,
    this.uppercase = false,
  });

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        textCapitalization: widget.uppercase ? TextCapitalization.characters : TextCapitalization.words,
        decoration: InputDecoration(labelText: widget.label, border: const OutlineInputBorder()),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Болих')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_controller.text), child: Text(widget.action)),
      ],
    );
  }
}
