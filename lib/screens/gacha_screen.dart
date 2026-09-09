import 'package:flutter/material.dart';

import '../data/cards.dart';
import '../data/theme.dart';
import '../models/card.dart';
import '../models/dopaminer.dart';
import '../models/gacha.dart';
import '../models/save_data.dart';
import '../widgets/chara.dart';
import 'deck_list_screen.dart';
import 'exchange_staging.dart';
import 'pachinko_staging.dart';

class GachaScreen extends StatefulWidget {
  final SaveData save;
  const GachaScreen({super.key, required this.save});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  PullResult? last;
  bool busy = false;

  SaveData get save => widget.save;

  Future<void> _roll() async {
    if (busy || save.tickets < 1) return;
    setState(() => busy = true);
    final result = Gacha.roll(save);
    await save.commit();
    await _stage(result);
  }

  Future<void> _exchange() async {
    if (busy || save.fragments < 10) return;
    setState(() => busy = true);
    final result = Gacha.exchange(save);
    await save.commit();
    if (save.settings.anim) {
      await Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => ExchangeStaging(result: result),
      ));
    }
    if (!mounted) return;
    setState(() {
      last = result;
      busy = false;
    });
  }

  /// パチンコ風の演出を挟んでから結果を表示する。
  /// 演出中は別ルートが上に乗るので、多重起動は起きない。
  Future<void> _stage(PullResult r) async {
    if (save.settings.anim) {
      await Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) =>
            PachinkoStaging(result: r, fragments: save.fragments),
      ));
    }
    if (!mounted) return;
    setState(() {
      last = r;
      busy = false;
    });
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
                    const Text('ガチャ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    _ticketPill(),
                  ]),
                  const SizedBox(height: 12),
                  _fragmentBar(),
                  const SizedBox(height: 12),
                  _capsuleBox(),
                  if (last != null) ...[
                    const SizedBox(height: 10),
                    _resultCard(last!),
                  ],
                  const SizedBox(height: 12),
                  Expanded(child: SingleChildScrollView(child: _rates())),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (busy || save.tickets < 1) ? null : _roll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.dopa,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF3A3050),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(busy ? '演出中…' : '1回引く（🎫1）',
                          style: const TextStyle(
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

  Widget _ticketPill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2114),
          border: Border.all(color: const Color(0xFF5C4620)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text('🎫 ${save.tickets}',
            style: const TextStyle(
                color: C.gold, fontSize: 12, fontWeight: FontWeight.bold)),
      );

  Widget _fragmentBar() {
    final f = save.fragments;
    final enough = f >= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2114),
        border: Border.all(color: const Color(0xFF5C4620)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('🧩', style: TextStyle(fontSize: 17)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('かけら $f / 10',
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFFFCF8A),
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: (f / 10).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: const Color(0xFF0D0A12),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFFFF9F1C)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          ElevatedButton(
            onPressed: (busy || !enough) ? null : _exchange,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9F1C),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF3A3050),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
            ),
            child: Text(enough ? 'SDと交換' : '交換',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _capsuleBox() => Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              last == null
                  ? '🎰'
                  : last!.isHit
                      ? '✨'
                      : last!.isFragment
                          ? '🧩'
                          : '🎁',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 10),
            const Text('チケット1枚で1回',
                style: TextStyle(fontSize: 12, color: C.sub)),
          ],
        ),
      );

  // ---------- 結果カード ----------
  Widget _resultCard(PullResult r) {
    final hit = r.isHit;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: hit ? const Color(0xFF3A2612) : C.panel,
        border: Border.all(color: hit ? const Color(0xFF7A4A12) : C.line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: hit
            ? const [
                BoxShadow(color: Color(0x40FF9F1C), blurRadius: 24),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF171122),
              border: Border.all(color: C.line),
              borderRadius: BorderRadius.circular(11),
            ),
            child: _preview(r),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (r.card != null)
                        _tag(r.card!.rarity.label,
                            r.card!.isSd
                                ? const Color(0xFF5C3A12)
                                : const Color(0xFF2B3A5C),
                            r.card!.isSd
                                ? const Color(0xFFFFCF8A)
                                : const Color(0xFF9DC0FF)),
                      Text(r.displayName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      if (r.kind == PullKind.sdCard ||
                          r.kind == PullKind.part)
                        _tag('NEW', C.dopa, Colors.white),
                      if (r.fragmentGain > 0)
                        _tag('🧩 +${r.fragmentGain}',
                            const Color(0xFF5C4620), const Color(0xFFFFCF8A)),
                    ]),
                if (r.card != null) ...[
                  const SizedBox(height: 5),
                  Wrap(spacing: 8, children: [
                    _eff('頭脳', r.card!.brain, C.brain),
                    _eff('ドパ欲', r.card!.dopa, C.dopa),
                    _eff('人間性', r.card!.human, C.human),
                  ]),
                ],
                const SizedBox(height: 5),
                Text(
                  r.isFragment
                      ? '${r.note}\n現在 ${save.fragments} / 10 個'
                      : r.note,
                  style:
                      const TextStyle(fontSize: 11, color: C.sub, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 引いたものの見た目
  Widget _preview(PullResult r) {
    if (r.card != null) {
      return Text(r.isFragment ? '🧩' : '🃏',
          style: const TextStyle(fontSize: 28));
    }
    final key = r.partKey!;
    // 色パーツは色見本、形パーツは実際のキャラで見せる
    if (key == 'hairColor' || key == 'skin' || key == 'cloth') {
      final color = switch (key) {
        'hairColor' => Parts.hairColors[r.partIndex],
        'skin' => Parts.skins[r.partIndex],
        _ => Parts.clothes[r.partIndex],
      };
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white24, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }
    final look = Look();
    if (key == 'hair') look.hair = r.partIndex;
    if (key == 'face') look.face = r.partIndex;
    return CharaView(look: look, size: CharaSize.tile);
  }

  Widget _tag(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, color: fg, fontWeight: FontWeight.w900)),
      );

  Widget _eff(String k, int v, Color color) => Text(
        '$k ${v > 0 ? '+' : ''}$v',
        style: TextStyle(
            fontSize: 11.5, color: color, fontWeight: FontWeight.bold),
      );

  // ---------- 確率表 ----------
  Widget _rates() {
    final left = Gacha.lockedParts(save).length;
    final exhausted = left == 0;
    final allSd = cardsOf(Rarity.sd).length;
    final yet = allSd - save.ownedSd.length;

    // 表示は定数から計算する。パーツ全解放後はパーツ枠がSDへ回る。
    final sdPct =
        exhausted ? GachaRates.sdPercent + GachaRates.partPercent : GachaRates.sdPercent;
    final dPct = GachaRates.dPercent;
    final partPct = exhausted ? 0 : GachaRates.partPercent;
    final newPct = (Gacha.newSdRate(save) * 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: C.panel,
        border: Border.all(color: C.line),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('排出内容と確率',
              style: TextStyle(
                  fontSize: 12.5, color: C.sub, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _rateRow('SDカード', exhausted ? 'パーツ枠を含む' : '全$allSd種', '$sdPct%',
              C.sd,
              top: false),
          _rateRow('Dカード', '通常・10種', '$dPct%', const Color(0xFF9DC0FF)),
          _rateRow('キャラメイクのパーツ',
              exhausted ? '全解放済み' : '残り $left種', '$partPct%', C.txt),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(children: [
              Expanded(
                  flex: sdPct,
                  child: const ColoredBox(
                      color: C.sd, child: SizedBox(height: 5))),
              Expanded(
                  flex: dPct,
                  child: const ColoredBox(
                      color: Color(0xFF4A6BB5), child: SizedBox(height: 5))),
              if (partPct > 0)
                Expanded(
                    flex: partPct,
                    child: const ColoredBox(
                        color: Color(0xFF6B5A8A), child: SizedBox(height: 5))),
            ]),
          ),
          const SizedBox(height: 12),

          // 実際に「新しいSDカード」が手に入る確率。集めるほど下がる。
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2114),
              border: Border.all(color: const Color(0xFF5C4620)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('新しいSDが出る確率',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFFCF8A),
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  yet == 0 ? '— （全種所持）' : '${newPct.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFFCF8A),
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '未所持 $yet種 ／ 所持済みを引くと 🧩かけら3個 になるため、\n'
            '集まるほど新規入手率は下がります',
            style: const TextStyle(fontSize: 10.5, color: C.sub, height: 1.7),
          ),

          const SizedBox(height: 11),
          const Text(
            '・Dカードは最初から編成できるため、出ると 🧩かけら1個 になります\n'
            '・所持済みのSDカードを引くと 🧩かけら3個 になります\n'
            '・🧩10個でSDカード1枚と交換できます（未所持を優先）\n'
            '・パーツを全解放すると、パーツ枠はSDカードに置き換わります',
            style: TextStyle(fontSize: 11, color: C.sub, height: 1.85),
          ),
        ],
      ),
    );
  }

  Widget _rateRow(String name, String note, String rate, Color color,
      {bool top = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: top
            ? const Border(top: BorderSide(color: C.line))
            : null,
      ),
      child: Row(children: [
        Text(name,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(note,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: C.sub)),
        ),
        Text(rate,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}