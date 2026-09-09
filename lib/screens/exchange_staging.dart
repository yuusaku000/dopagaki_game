import 'dart:math';

import 'package:flutter/material.dart';

import '../data/theme.dart';
import '../models/gacha.dart';
import '../widgets/staging_effects.dart';

/// かけら10個 → SDカード交換の演出。
/// 毎回ランダムで演出タイプが変わる。パチンコ演出とは別物。
class ExchangeStaging extends StatefulWidget {
  final PullResult result;
  const ExchangeStaging({super.key, required this.result});

  @override
  State<ExchangeStaging> createState() => _ExchangeStagingState();
}

enum _Mode { fuse, machine, ritual, slot }

class _ExchangeStagingState extends State<ExchangeStaging>
    with TickerProviderStateMixin {
  late final _Mode mode;
  bool _revealed = false;
  bool _canClose = false;

  late final AnimationController _main = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    mode = _Mode.values[Random().nextInt(_Mode.values.length)];
    _run();
  }

  Future<void> _run() async {
    await _main.forward();
    if (!mounted) return;
    setState(() => _revealed = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _canClose = true);
  }

  @override
  void dispose() {
    _main.dispose();
    super.dispose();
  }

  void _tap() {
    if (_canClose) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: Material(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.1,
                    colors: [
                      const Color(0xFF3A2612).withValues(alpha: 0.7),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
            if (_revealed) const Positioned.fill(child: ConfettiRain()),
            SafeArea(
              child: Center(
                child: _revealed ? _resultView() : _buildView(),
              ),
            ),
            if (_canClose)
              const Align(
                alignment: Alignment(0, 0.88),
                child: Text('タップして進む',
                    style: TextStyle(fontSize: 12, color: Color(0xFFC3A8DD))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildView() {
    return AnimatedBuilder(
      animation: _main,
      builder: (_, __) {
        return switch (mode) {
          _Mode.fuse => _fuse(_main.value),
          _Mode.machine => _machine(_main.value),
          _Mode.ritual => _ritual(_main.value),
          _Mode.slot => _slot(_main.value),
        };
      },
    );
  }

  // かけらが中央に吸い込まれて融合する
  Widget _fuse(double t) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 10; i++)
            _fragAt(i, t),
          Opacity(
            opacity: (t - 0.6).clamp(0.0, 0.4) / 0.4,
            child: Transform.scale(
              scale: 0.5 + t * 0.8,
              child: Text('🃏',
                  style: TextStyle(fontSize: 40 + t * 30, shadows: const [
                    Shadow(color: Color(0xFFFFD54F), blurRadius: 30)
                  ])),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Text('融合',
                style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 6,
                    color: C.sd.withValues(alpha: t))),
          ),
        ],
      ),
    );
  }

  Widget _fragAt(int i, double t) {
    final angle = i / 10 * 2 * pi;
    final pull = Curves.easeIn.transform(t.clamp(0.0, 0.7) / 0.7);
    final radius = 110 * (1 - pull);
    return Transform.translate(
      offset: Offset(cos(angle) * radius, sin(angle) * radius),
      child: Opacity(
        opacity: (1 - pull).clamp(0.0, 1.0),
        child: const Text('🧩', style: TextStyle(fontSize: 24)),
      ),
    );
  }

  // ガチャマシンのハンドルが回る
  Widget _machine(double t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🎰',
            style: TextStyle(
                fontSize: 90,
                shadows: [
                  Shadow(color: C.sd.withValues(alpha: t), blurRadius: 24)
                ])),
        const SizedBox(height: 16),
        Transform.rotate(
          angle: t * 6 * pi,
          child: const Text('🔧', style: TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 16),
        Text('かけらを投入',
            style: TextStyle(
                fontSize: 14,
                letterSpacing: 3,
                color: C.sub.withValues(alpha: 0.5 + t * 0.5))),
      ],
    );
  }

  // 魔法陣が光る
  Widget _ritual(double t) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: t * 2 * pi,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: C.sd.withValues(alpha: t * 0.8), width: 3),
              ),
            ),
          ),
          Transform.rotate(
            angle: -t * 3 * pi,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFC084FC).withValues(alpha: t * 0.8),
                    width: 2),
              ),
            ),
          ),
          Text('🧩',
              style: TextStyle(fontSize: 30 + t * 24, shadows: [
                Shadow(color: C.sd.withValues(alpha: t), blurRadius: 30)
              ])),
        ],
      ),
    );
  }

  // スロットが揃う
  Widget _slot(double t) {
    final spin = t < 0.7;
    final n = spin ? (t * 40).floor() % 3 : 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              width: 62,
              height: 78,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF120E18),
                border: Border.all(
                    color: spin ? C.line : C.sd, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                spin ? ['🧩', '💊', '🃏'][(n + i) % 3] : '🃏',
                style: const TextStyle(fontSize: 34),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(spin ? '交換中…' : '揃った！',
            style: TextStyle(
                fontSize: 15,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                color: spin ? C.sub : C.sd)),
      ],
    );
  }

  // 結果
  Widget _resultView() {
    final c = widget.result.card!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RainbowText('交換 成立', size: 30),
          const SizedBox(height: 16),
          const Text('🃏', style: TextStyle(fontSize: 46)),
          const SizedBox(height: 8),
          RainbowText(c.title, size: 24),
          const SizedBox(height: 12),
          Text(
            '頭脳 ${_s(c.brain)}　ドパ欲 +${c.dopa}　人間性 ${_s(c.human)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFFC3A8DD)),
          ),
          const SizedBox(height: 10),
          Text(widget.result.note,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: C.sub, height: 1.6)),
        ],
      ),
    );
  }

  String _s(int v) => v > 0 ? '+$v' : '$v';
}