import 'package:flutter/material.dart';

import '../data/cards.dart';
import '../data/theme.dart';
import '../models/dopaminer.dart';
import '../models/save_data.dart';
import 'deck_edit_screen.dart';

class DeckListScreen extends StatefulWidget {
  final SaveData save;
  const DeckListScreen({super.key, required this.save});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  SaveData get save => widget.save;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    BackChip(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 10),
                    const Text('デッキ編成',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    '1デッキは D 12枚 ＋ SD 4枚 の計16枚。同じカードは3枚まで。\n'
                    '育成中は、このデッキとドパミナーのカードから毎ターン3枚が抽選されます。',
                    style:
                        TextStyle(fontSize: 11.5, color: C.sub, height: 1.75),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      itemCount: save.decks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (_, i) => _deckTile(i),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _deckTile(int i) {
    final dk = save.decks[i];
    final active = i == save.activeDeck;

    // 多く積んでいるカードを4種まで並べる
    final counts = <String, int>{};
    for (final id in [...dk.d, ...dk.sd]) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final top = (counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .map((e) =>
            '${cardById(e.key).title}${e.value > 1 ? '×${e.value}' : ''}')
        .join('、');

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DeckEditScreen(save: save, index: i),
        ));
        if (mounted) setState(() {});
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: C.panel,
          border: Border.all(color: active ? C.dopa : C.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(dk.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(width: 7),
              if (active)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                      color: C.gold, borderRadius: BorderRadius.circular(6)),
                  child: const Text('使用中',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF3A2C00),
                          fontWeight: FontWeight.w900)),
                ),
              const Spacer(),
              if (!active)
                TextButton(
                  onPressed: () async {
                    save.activeDeck = i;
                    await save.commit();
                    if (mounted) setState(() {});
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: C.dopa,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('使う', style: TextStyle(fontSize: 12)),
                ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              MiniTag('D ${dk.d.length}/12',
                  bg: const Color(0xFF2B3A5C), fg: const Color(0xFF9DC0FF)),
              const SizedBox(width: 5),
              MiniTag('SD ${dk.sd.length}/4',
                  bg: const Color(0xFF5C3A12), fg: const Color(0xFFFFCF8A)),
              if (!dk.isComplete) ...[
                const SizedBox(width: 7),
                const Text('未完成',
                    style: TextStyle(fontSize: 11, color: C.warn)),
              ],
            ]),
            const SizedBox(height: 6),
            Text(top,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: C.sub)),
          ],
        ),
      ),
    );
  }
}

/// 各画面で使う小さめの戻るボタン
class BackChip extends StatelessWidget {
  final VoidCallback onTap;
  const BackChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: C.sub,
          side: const BorderSide(color: C.line),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: const Text('← 戻る', style: TextStyle(fontSize: 12)),
      );
}

/// 小さなラベル
class MiniTag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const MiniTag(this.text, {super.key, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, color: fg, fontWeight: FontWeight.w900)),
      );
}