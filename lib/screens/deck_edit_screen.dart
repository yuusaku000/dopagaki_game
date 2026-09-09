import 'package:flutter/material.dart';

import '../data/cards.dart';
import '../data/theme.dart';
import '../models/card.dart';
import '../models/dopaminer.dart';
import '../models/save_data.dart';
import 'deck_list_screen.dart';

class DeckEditScreen extends StatefulWidget {
  final SaveData save;
  final int index;

  const DeckEditScreen({super.key, required this.save, required this.index});

  @override
  State<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends State<DeckEditScreen> {
  Rarity tab = Rarity.d;

  SaveData get save => widget.save;
  Deck get deck => save.decks[widget.index];

  List<String> get slots => tab == Rarity.d ? deck.d : deck.sd;
  int get slotMax => tab == Rarity.d ? Deck.maxD : Deck.maxSd;

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1300),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _add(GameCard c) async {
    final arr = c.rarity == Rarity.d ? deck.d : deck.sd;
    final max = c.rarity == Rarity.d ? Deck.maxD : Deck.maxSd;
    final cap = save.copyLimit(c);

    if (cap == 0) {
      _toast('このSDカードはまだ所持していません');
      return;
    }
    if (arr.length >= max) {
      _toast('${c.rarity.label}枠が満杯です（$max枚）');
      return;
    }
    if (arr.where((x) => x == c.id).length >= cap) {
      _toast('同じカードは3枚までです');
      return;
    }
    arr.add(c.id);
    await save.commit();
    if (mounted) setState(() {});
  }

  Future<void> _removeAt(int i) async {
    slots.removeAt(i);
    await save.commit();
    if (mounted) setState(() {});
  }

  Future<void> _removeById(String id) async {
    final arr = cardById(id).rarity == Rarity.d ? deck.d : deck.sd;
    final i = arr.lastIndexOf(id);
    if (i >= 0) {
      arr.removeAt(i);
      await save.commit();
      if (mounted) setState(() {});
    }
  }

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
                    Text(deck.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  _deckHead(),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('所持カード',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    const Text('同じカードは3枚まで',
                        style: TextStyle(fontSize: 10.5, color: C.sub)),
                  ]),
                  const SizedBox(height: 8),
                  Expanded(child: _collection()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- 上部：タブとスロット ----------
  Widget _deckHead() {
    final full = slots.length == slotMax;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: C.panel,
        border: Border.all(color: C.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(children: [
            _tabButton('D 枠', Rarity.d),
            const SizedBox(width: 8),
            _tabButton('SD 枠', Rarity.sd),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            Text(
              tab == Rarity.d ? 'Dカード（通常）' : 'SDカード（テスト合格で解禁）',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text('${slots.length} / $slotMax 枚',
                style: TextStyle(
                    fontSize: 12,
                    color: full ? C.human : C.sub,
                    fontWeight: full ? FontWeight.w800 : FontWeight.normal)),
          ]),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slotMax,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              mainAxisExtent: 68,
            ),
            itemBuilder: (_, i) => _slot(i),
          ),
          const SizedBox(height: 7),
          Text(
            tab == Rarity.d ? 'スロットをタップで外す' : '🔒はテスト合格で使えるようになります',
            style: const TextStyle(fontSize: 10, color: C.sub),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, Rarity r) {
    final on = tab == r;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => tab = r),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? C.panel2 : C.panel,
            border: Border.all(color: on ? C.dopa : C.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  color: on ? C.txt : C.sub,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _slot(int i) {
    // 埋まっているスロット
    if (i < slots.length) {
      final c = cardById(slots[i]);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: () => _removeAt(i),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              decoration: BoxDecoration(
                color: c.isSd ? const Color(0xFF2B2018) : const Color(0xFF2A2138),
                border: Border.all(
                    color: c.isSd ? const Color(0xFF8A5C1F) : const Color(0xFF4A3A66)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c.title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9.5,
                          height: 1.2,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text('ド+${c.dopa}',
                      style: const TextStyle(fontSize: 9, color: C.dopa)),
                ],
              ),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF5C2030),
                border: Border.all(color: const Color(0xFF7A2A3E)),
                shape: BoxShape.circle,
              ),
              child: const Text('−',
                  style: TextStyle(
                      fontSize: 11,
                      height: 1,
                      color: Color(0xFFFFB0C0),
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      );
    }

    // 空きスロット
    final lockedSd = tab == Rarity.sd;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF171122),
        border: Border.all(color: C.line, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lockedSd) ...[
            const Text('🔒', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 3),
            Text(i < 2 ? '4年テスト合格' : '5年テスト合格',
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8, color: C.sub, height: 1.2)),
          ] else
            const Text('空き', style: TextStyle(fontSize: 9.5, color: C.sub)),
        ],
      ),
    );
  }

  // ---------- 下部：所持カード ----------
  Widget _collection() {
    final pool = cardsOf(tab);
    return ListView.separated(
      itemCount: pool.length,
      separatorBuilder: (_, __) => const SizedBox(height: 7),
      itemBuilder: (_, i) => _collectionRow(pool[i]),
    );
  }

  Widget _collectionRow(GameCard c) {
    final arr = c.rarity == Rarity.d ? deck.d : deck.sd;
    final inDeck = arr.where((x) => x == c.id).length;
    final cap = save.copyLimit(c);
    final locked = cap == 0;
    final canAdd = inDeck < cap && arr.length < slotMax;

    return Opacity(
      opacity: locked ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: inDeck > 0 ? const Color(0xFF1C2334) : C.panel,
          border: Border.all(
            color: inDeck > 0
                ? const Color(0xFF4A6BB5)
                : (c.isSd ? const Color(0xFF7A4A12) : C.line),
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (locked)
                          const Text('🔒 ', style: TextStyle(fontSize: 11)),
                        Flexible(
                          child: Text(c.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 7),
                        // 編成数をドットで表示
                        Row(
                          children: List.generate(
                            Deck.maxCopy,
                            (k) => Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: k < inDeck
                                    ? C.dopa
                                    : const Color(0xFF3A3050),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Wrap(spacing: 8, children: [
                        _eff('頭', c.brain, C.brain),
                        _eff('ド', c.dopa, C.dopa),
                        _eff('人', c.human, C.human),
                        Text('／ ${c.desc}',
                            style: const TextStyle(
                                fontSize: 10.5, color: Color(0xFF5C5170))),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _squareButton('−', inDeck > 0 ? () => _removeById(c.id) : null,
                    width: 28),
                const SizedBox(width: 6),
                _squareButton('＋', canAdd ? () => _add(c) : null, width: 34),
              ],
            ),
            if (c.isSd)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  locked ? '🔒 未所持（ガチャで入手）' : '所持済み ／ 3枚まで編成可',
                  style: const TextStyle(fontSize: 10.5, color: C.sub),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _eff(String k, int v, Color color) => Text(
        '$k${v > 0 ? '+' : ''}$v',
        style: TextStyle(fontSize: 10.5, color: color),
      );

  Widget _squareButton(String label, VoidCallback? onTap,
      {double width = 32}) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.25,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: width,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.panel2,
            border: Border.all(color: C.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}