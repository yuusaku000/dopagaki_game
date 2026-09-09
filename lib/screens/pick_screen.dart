import 'package:flutter/material.dart';

import '../data/theme.dart';
import '../models/dopaminer.dart';
import '../models/save_data.dart';
import '../widgets/dopaminer_tile.dart';
import 'deck_list_screen.dart';
import 'run_screen.dart';

class PickScreen extends StatefulWidget {
  final SaveData save;
  final String name;
  final Look look;

  const PickScreen({
    super.key,
    required this.save,
    required this.name,
    required this.look,
  });

  @override
  State<PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  final List<int> picked = [];
  SortKey sort = SortKey.newest;

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
                    const Text('持ち込み',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  const Text('デッキを選ぶ',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 7),
                  ...List.generate(save.decks.length, (i) => _deckTile(i)),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => DeckListScreen(save: save)));
                        if (mounted) setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: C.txt,
                        side: const BorderSide(color: C.line),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('デッキを編成する',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('ドパミナー',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${picked.length} / 2',
                        style: const TextStyle(fontSize: 11, color: C.sub)),
                  ]),
                  const SizedBox(height: 7),
                  SortDropdown(
                    value: sort,
                    onChanged: (v) => setState(() => sort = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _dopaminerList()),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _start,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.dopa,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('育成開始',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          save.activeDeck = i;
          await save.commit();
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
                if (active) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                        color: C.gold,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('選択中',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF3A2C00),
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ]),
              const SizedBox(height: 5),
              Row(children: [
                _mini('D ${dk.d.length}/12', const Color(0xFF2B3A5C),
                    const Color(0xFF9DC0FF)),
                const SizedBox(width: 5),
                _mini('SD ${dk.sd.length}/4', const Color(0xFF5C3A12),
                    const Color(0xFFFFCF8A)),
                if (!dk.isComplete) ...[
                  const SizedBox(width: 7),
                  const Text('枚数が足りません',
                      style: TextStyle(fontSize: 11, color: C.warn)),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, color: fg, fontWeight: FontWeight.w900)),
      );

  Widget _dopaminerList() {
    if (save.dopaminers.isEmpty) {
      return const Center(
        child: Text('まだドパミナーがいません。',
            style: TextStyle(fontSize: 13, color: C.sub)),
      );
    }
    final order = sortedIndices(save.dopaminers, sort);
    return ListView.separated(
      itemCount: order.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, k) {
        final i = order[k];
        return DopaminerTile(
          d: save.dopaminers[i],
          selected: picked.contains(i),
          onTap: () => _toggle(i),
        );
      },
    );
  }

  void _toggle(int i) {
    setState(() {
      if (picked.contains(i)) {
        picked.remove(i);
      } else if (picked.length < 2) {
        picked.add(i);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('ドパミナーは2人までです'),
            duration: Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
          ));
      }
    });
  }

  void _start() {
    if (!save.deck.isComplete) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('デッキの枚数が足りません（D12枚・SD4枚）'),
          duration: Duration(milliseconds: 1600),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    final partners = picked.map((i) => save.dopaminers[i]).toList();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => RunScreen(
        save: save,
        name: widget.name,
        look: widget.look,
        partners: partners,
      ),
    ));
  }
}