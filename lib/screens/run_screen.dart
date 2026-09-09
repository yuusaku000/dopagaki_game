import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/cards.dart';
import '../data/theme.dart';
import '../models/card.dart';
import '../models/dopaminer.dart';
import '../models/run_state.dart';
import '../models/save_data.dart';
import '../widgets/chara.dart';
import '../widgets/room_bg.dart';

class RunScreen extends StatefulWidget {
  final SaveData save;
  final String name;
  final Look look;
  final List<Dopaminer> partners;

  const RunScreen({
    super.key,
    required this.save,
    required this.name,
    required this.look,
    required this.partners,
  });

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with TickerProviderStateMixin {
  late RunState run;

  /// ステータス変動を飛ばす演出用
  final List<_Fly> _flies = [];
  String _say = 'スマホ買ってもらった！';
  bool _finished = false;

  late final AnimationController _shake;
  Color? _flash;

  @override
  void initState() {
    super.initState();
    run = RunState.start(
      name: widget.name,
      look: widget.look,
      deck: widget.save.deck,
      partners: widget.partners,
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  bool get _anim => widget.save.settings.anim;

  void _choose(GameCard c) {
    if (_finished) return;
    final r = run.choose(c);

    if (_anim) {
      HapticFeedback.lightImpact();
      _addFly(r);
      if (c.human <= -10) _shake.forward(from: 0);
      if (r.testTurn) {
        setState(() => _flash = r.passed
            ? C.gold.withValues(alpha: 0.55)
            : Colors.red.withValues(alpha: 0.5));
        Future.delayed(const Duration(milliseconds: 480), () {
          if (mounted) setState(() => _flash = null);
        });
      }
    }

    setState(() => _say = r.line);
    if (run.isOver) {
      setState(() => _finished = true);
      _saveResult();
    }
  }

  void _addFly(TurnResult r) {
    final items = <_Fly>[];
    if (r.brain != 0) {
      items.add(_Fly(_sign(r.brain), C.brain, -0.5));
    }
    if (r.dopa != 0) items.add(_Fly('+${r.dopa}', C.dopa, 0));
    if (r.human != 0) items.add(_Fly(_sign(r.human), C.human, 0.5));
    setState(() => _flies.addAll(items));
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _flies.removeWhere(items.contains));
    });
  }

  String _sign(int v) => v > 0 ? '+$v' : '$v';

  Future<void> _saveResult() async {
    final s = widget.save;
    s.dopaminers.add(run.toDopaminer());
    s.tickets += run.failed ? 1 : 2;
    await s.commit();
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
                  _header(),
                  const SizedBox(height: 8),
                  _stats(),
                  const SizedBox(height: 10),
                  Expanded(child: _stage()),
                  const SizedBox(height: 10),
                  if (_finished) _result() else _cards(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- ヘッダ ----------
  Widget _header() => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(run.dateLabel,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(run.name,
              style: const TextStyle(fontSize: 12, color: C.sub)),
          const Spacer(),
          Text('${run.turn.clamp(1, 36)} / 36',
              style: const TextStyle(fontSize: 12, color: C.sub)),
        ],
      );

  // ---------- ステータス ----------
  Widget _stats() {
    String humanHint() {
      if (run.human <= 0) return '人間性の喪失';
      if (run.human < 40) return '軽い鬱状態';
      if (run.human < 60) return 'すり減っている';
      return '良好';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: C.panel,
        border: Border.all(color: C.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _bar('頭脳', C.brain, run.brain, run.brain / run.passLine,
              '次の合格ライン ${run.passLine}'),
          const SizedBox(height: 9),
          _bar('ドパ欲', C.dopa, run.dopa, run.dopa / 700,
              '倍率 ×${run.multiplier.toStringAsFixed(2)}'),
          const SizedBox(height: 9),
          _bar('人間性', C.human, run.human, run.human / 100, humanHint()),
        ],
      ),
    );
  }

  Widget _bar(String label, Color color, int value, double ratio, String hint) {
    return Row(
      children: [
        SizedBox(
            width: 44,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: ratio.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 400),
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF0D0A12),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(hint, style: const TextStyle(fontSize: 10, color: C.sub)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text('$value',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12, fontFeatures: [FontFeature.tabularFigures()])),
        ),
      ],
    );
  }

  // ---------- ステージ ----------
  Widget _stage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: RoomBackground(season: run.season)),
          // キャラ
          AnimatedBuilder(
            animation: _shake,
            builder: (_, child) {
              final dx = _anim ? sin(_shake.value * pi * 4) * 5 : 0.0;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: CharaView(
              look: run.look,
              human: run.human,
              dopa: run.dopa,
              size: CharaSize.stage,
            ),
          ),
          // イベント帯
          if (run.eventLabel != null && !_finished)
            Positioned(
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xD93A2C14),
                  border: Border.all(color: const Color(0xFF5C4620)),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(run.eventLabel!,
                    style: const TextStyle(fontSize: 12, color: C.warn)),
              ),
            ),
          // セリフ
          if (widget.save.settings.showLine)
            Positioned(
              top: 34,
              left: 16,
              right: 16,
              child: Center(child: _bubble(_say)),
            ),
          // 飛ぶ数値
          ..._flies.map((f) => _FlyText(key: ValueKey(f), fly: f)),
          // テストのフラッシュ
          if (_flash != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 100),
                  child: Container(color: _flash),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bubble(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF221C2C), fontSize: 12.5, height: 1.45)),
      );

  // ---------- カード ----------
  Widget _cards() {
    return Column(
      children: run.hand.map((c) {
        final fromPartner = run.isFromPartner(c);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _choose(c),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.isSd ? const Color(0xFF2B2018) : C.panel,
                border:
                    Border.all(color: c.isSd ? const Color(0xFF8A5C1F) : C.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _tag(c.rarity.label,
                              c.isSd ? const Color(0xFF5C3A12) : const Color(0xFF2B3A5C),
                              c.isSd ? const Color(0xFFFFCF8A) : const Color(0xFF9DC0FF)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(c.title,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (fromPartner) ...[
                            const SizedBox(width: 6),
                            _tag('ドパミナー', const Color(0xFF3A2B52),
                                const Color(0xFFC9A8FF)),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text(c.desc,
                            style:
                                const TextStyle(fontSize: 11, color: C.sub)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (widget.save.settings.showEffect)
                    Row(children: [
                      _chip('頭', c.brain, C.brain),
                      const SizedBox(width: 6),
                      _chip('ド', c.dopa, C.dopa),
                      const SizedBox(width: 6),
                      _chip('人', c.human, C.human),
                    ])
                  else
                    const Text('？', style: TextStyle(color: C.sub)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tag(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: TextStyle(
                fontSize: 9, color: fg, fontWeight: FontWeight.w900)),
      );

  Widget _chip(String k, int v, Color color) => Text(
        v == 0 ? '${k}0' : '$k${v > 0 ? '+' : ''}$v',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: v == 0 ? const Color(0xFF4A4159) : color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );

  // ---------- 結果 ----------
  Widget _result() {
    final b = run.brain * 3, h = run.human * 5, d = run.dopa * 2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.panel,
        border: Border.all(color: C.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(run.failed ? '育成失敗：人間性の喪失' : '育成完了',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(run.failed ? '—' : '${run.finalScore}',
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w900, color: C.dopa)),
          Text(run.finalRank,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w900, color: C.gold)),
          const SizedBox(height: 8),
          Text(
            '頭脳 ${run.brain} × 3 ＝ $b\n'
            '人間性 ${run.human} × 5 ＝ $h\n'
            'ドパ欲 ${run.dopa} × 2 ＝ $d',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: C.sub, height: 1.8),
          ),
          const SizedBox(height: 8),
          Text(
            '継承カード：${run.inheritedCards.map((e) => cardById(e).title).join('、')}\n'
            '🎫 ${run.failed ? 1 : 2}枚 獲得',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: C.sub, height: 1.7),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: C.dopa,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ホームへ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// 数値が飛ぶ演出
// =====================================================================
class _Fly {
  final String text;
  final Color color;
  final double offsetX;
  _Fly(this.text, this.color, this.offsetX);
}

class _FlyText extends StatefulWidget {
  final _Fly fly;
  const _FlyText({super.key, required this.fly});

  @override
  State<_FlyText> createState() => _FlyTextState();
}

class _FlyTextState extends State<_FlyText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Positioned(
          bottom: 60 + t * 46,
          left: null,
          child: Transform.translate(
            offset: Offset(widget.fly.offsetX * 90, 0),
            child: Opacity(
              opacity: t < 0.2 ? t / 0.2 : (1 - (t - 0.2) / 0.8),
              child: Text(
                widget.fly.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: widget.fly.color,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 2))
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}