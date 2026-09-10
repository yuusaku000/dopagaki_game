import 'dart:math';

import 'package:flutter/material.dart';

import '../models/dopaminer.dart';
import 'chara.dart';

// =====================================================================
// 群予告：ドパガキの群れが画面を横切る
// =====================================================================
class CrowdOverlay extends StatefulWidget {
  final bool hot; // 熱い群れ（数が多く、金色が混ざる）
  const CrowdOverlay({super.key, this.hot = false});

  @override
  State<CrowdOverlay> createState() => _CrowdOverlayState();
}

class _CrowdOverlayState extends State<CrowdOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final List<_Runner> _runners;

  @override
  void initState() {
    super.initState();
    final r = Random();
    final n = widget.hot ? 11 : 7;
    _runners = List.generate(n, (i) {
      return _Runner(
        look: Look(
          hair: r.nextInt(8),
          hairColor: r.nextInt(8),
          skin: r.nextInt(5),
          face: r.nextInt(3),
          cloth: r.nextInt(7),
        ),
        delay: r.nextDouble() * 0.45,
        y: 0.1 + r.nextDouble() * 0.7,
        size: 40 + r.nextDouble() * 34,
        gold: widget.hot && i == n - 1, // 最後の1体だけ金
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, box) => AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Stack(
            children: _runners.map((r) {
              final t = ((_c.value - r.delay) / (1 - r.delay)).clamp(0.0, 1.0);
              if (t <= 0) return const SizedBox.shrink();
              final x = box.maxWidth * 1.15 * (1 - t) - r.size;
              return Positioned(
                left: x,
                top: box.maxHeight * r.y,
                child: Opacity(
                  opacity: t < 0.1 ? t / 0.1 : (t > 0.9 ? (1 - t) / 0.1 : 1),
                  child: r.gold
                      ? ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                              Color(0xFFFFD54F), BlendMode.modulate),
                          child: CharaView(look: r.look, size: r.size),
                        )
                      : CharaView(look: r.look, human: 20, size: r.size),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _Runner {
  final Look look;
  final double delay;
  final double y;
  final double size;
  final bool gold;
  _Runner({
    required this.look,
    required this.delay,
    required this.y,
    required this.size,
    required this.gold,
  });
}

// =====================================================================
// 役物落下：スマホが上から降ってくる
// =====================================================================
class DropObject extends StatelessWidget {
  final Color color;
  const DropObject({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.bounceOut,
        builder: (_, t, __) => Align(
          alignment: Alignment(0, -1.2 + t * 1.2),
          child: Transform.rotate(
            angle: (1 - t) * 2.4,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                border: Border.all(color: color, width: 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.6), blurRadius: 26)
                ],
              ),
              child: const Text('📱', style: TextStyle(fontSize: 46)),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// ボタン演出：押すと結果が動く
// =====================================================================
class PushButton extends StatefulWidget {
  final Color color;
  final VoidCallback onPush;
  const PushButton({super.key, required this.color, required this.onPush});

  @override
  State<PushButton> createState() => _PushButtonState();
}

class _PushButtonState extends State<PushButton>
    // AnimationController を2つ使うので Single ではないほうを使う
    with TickerProviderStateMixin {
  late final AnimationController _gauge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _gauge.dispose();
    _bounce.dispose();
    super.dispose();
  }

  /// 画面の狭いほうに合わせてボタンを大きくする
  double get _size {
    final m = MediaQuery.of(context).size;
    final base = m.shortestSide;
    return (base * 0.42).clamp(120.0, 200.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 待っていることを示す往復ゲージ
            SizedBox(
              width: 200,
              child: AnimatedBuilder(
                animation: _gauge,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    backgroundColor: const Color(0xFF221A2E),
                    valueColor: AlwaysStoppedAnimation(widget.color),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            AnimatedBuilder(
              animation: _bounce,
              builder: (_, child) => Transform.scale(
                scale: 1 + _bounce.value * 0.09,
                child: child,
              ),
              child: GestureDetector(
                onTap: widget.onPush,
                child: Container(
                  width: _size,
                  height: _size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      widget.color,
                      widget.color.withValues(alpha: 0.35),
                    ]),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                          color: widget.color.withValues(alpha: 0.7),
                          blurRadius: 34)
                    ],
                  ),
                  child: Text('PUSH',
                      style: TextStyle(
                          fontSize: _size * 0.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('押せ',
                style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 6,
                    color: Color(0xFFC3A8DD),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// カウントダウン
// =====================================================================
class CountdownText extends StatelessWidget {
  final int value;
  final Color color;
  const CountdownText({super.key, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(value),
          tween: Tween(begin: 1.8, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: Text(
            value > 0 ? '$value' : 'GO',
            style: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w900,
              color: color,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.8), blurRadius: 30),
                const Shadow(color: Colors.black, blurRadius: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// セリフ予告：吹き出しだけが出る
// =====================================================================
class LineNotice extends StatelessWidget {
  final String text;
  final Color color;
  const LineNotice({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 24)
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF221C2C),
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// 火花：当たり時に散る
// =====================================================================
class BurstOverlay extends StatefulWidget {
  const BurstOverlay({super.key});

  @override
  State<BurstOverlay> createState() => _BurstOverlayState();
}

class _BurstOverlayState extends State<BurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  final _rand = Random();
  late final List<_Particle> _parts = List.generate(60, (i) {
    final a = _rand.nextDouble() * 2 * pi;
    final d = 90 + _rand.nextDouble() * 230;
    return _Particle(cos(a) * d, sin(a) * d, _colors[i % _colors.length]);
  });

  static const _colors = [
    Color(0xFFFF3D78),
    Color(0xFFFFD54F),
    Color(0xFF4CCF7D),
    Color(0xFF4FA3FF),
    Color(0xFFC084FC),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = Curves.easeOutCubic.transform(_c.value);
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: _parts
                  .map((p) => Transform.translate(
                        offset: Offset(p.dx * t, p.dy * t),
                        child: Opacity(
                          opacity: (1 - t).clamp(0.0, 1.0),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: p.color, shape: BoxShape.circle),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double dx, dy;
  final Color color;
  _Particle(this.dx, this.dy, this.color);
}

// =====================================================================
// 虹色の文字
// =====================================================================
class RainbowText extends StatelessWidget {
  final String text;
  final double size;
  const RainbowText(this.text, {super.key, required this.size});

  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (rect) => const LinearGradient(colors: [
          Color(0xFFFF3D78),
          Color(0xFFFFD54F),
          Color(0xFF4CCF7D),
          Color(0xFF4FA3FF),
          Color(0xFFC084FC),
        ]).createShader(rect),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      );
}

// =====================================================================
// ブラックアウト：画面がプツッと消える
// =====================================================================
class BlackoutOverlay extends StatefulWidget {
  const BlackoutOverlay({super.key});

  @override
  State<BlackoutOverlay> createState() => _BlackoutOverlayState();
}

class _BlackoutOverlayState extends State<BlackoutOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          // ブラウン管が消えるように、縦→横の順に潰れる
          final vScale = t < 0.35 ? 1 - (t / 0.35) * 0.97 : 0.03;
          final hScale = t < 0.35 ? 1.0 : (t < 0.6 ? 1 - (t - 0.35) / 0.25 : 0.0);
          final glow = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.black)),
              Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..scale(hScale, vScale),
                  child: Container(
                    width: 320,
                    height: 320,
                    color: Colors.white.withValues(alpha: glow),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// ドパミン放出：脳の中の粒がぶわっと湧く
// =====================================================================
class DopamineBurst extends StatefulWidget {
  final bool strong;
  const DopamineBurst({super.key, this.strong = false});

  @override
  State<DopamineBurst> createState() => _DopamineBurstState();
}

class _DopamineBurstState extends State<DopamineBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.strong ? 2200 : 1600),
  )..forward();

  final _rand = Random();
  late final List<_Bubble> _bubbles = List.generate(
    widget.strong ? 52 : 26,
    (i) => _Bubble(
      x: _rand.nextDouble(),
      delay: _rand.nextDouble() * 0.4,
      size: 8 + _rand.nextDouble() * 22,
      drift: (_rand.nextDouble() - 0.5) * 70,
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, box) => AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Stack(
            children: _bubbles.map((b) {
              final raw =
                  ((_c.value - b.delay) / (1 - b.delay)).clamp(0.0, 1.0);
              if (raw <= 0) return const SizedBox.shrink();
              // 溜め：前半はほとんど動かず下で膨らみ、後半で一気に上がる
              final t = raw < 0.45
                  ? raw * 0.18 / 0.45
                  : 0.18 + (raw - 0.45) / 0.55 * 0.82;
              // 膨らみ：溜め中に大きくなる
              final grow = raw < 0.45 ? 0.4 + raw / 0.45 * 0.6 : 1.0;
              return Positioned(
                left: box.maxWidth * b.x + b.drift * t,
                top: box.maxHeight * (1.05 - t * 1.15),
                child: Opacity(
                  opacity: (raw < 0.45 ? raw / 0.45 : (1 - (t - 0.18) / 0.82))
                          .clamp(0.0, 1.0) *
                      0.85,
                  child: Container(
                    width: b.size * grow,
                    height: b.size * grow,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [
                        Color(0xFFFF9EC2),
                        Color(0x00FF3D78),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _Bubble {
  final double x, delay, size, drift;
  _Bubble({
    required this.x,
    required this.delay,
    required this.size,
    required this.drift,
  });
}

// =====================================================================
// 画面の揺れ。強い演出のときに全体を振動させる。
// =====================================================================
class ScreenShake extends StatefulWidget {
  final Widget child;
  final bool active;
  final double intensity;

  const ScreenShake({
    super.key,
    required this.child,
    required this.active,
    this.intensity = 6,
  });

  @override
  State<ScreenShake> createState() => _ScreenShakeState();
}

class _ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );

  final _rand = Random();

  @override
  void didUpdateWidget(ScreenShake old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          (_rand.nextDouble() - 0.5) * widget.intensity,
          (_rand.nextDouble() - 0.5) * widget.intensity,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// =====================================================================
// 大当たりファンファーレ
// 揃った瞬間に画面全体を虹色で埋め、巨大な文字とドパガキが乱舞する
// =====================================================================
class JackpotOverlay extends StatefulWidget {
  final String text;
  final String? subText;

  const JackpotOverlay({super.key, this.text = '大当たり', this.subText});

  @override
  State<JackpotOverlay> createState() => _JackpotOverlayState();
}

class _JackpotOverlayState extends State<JackpotOverlay>
    with TickerProviderStateMixin {
  /// 虹色の流れ・背景の回転
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  /// 文字の揺れ
  late final AnimationController _quake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 70),
  )..repeat();

  /// 登場のスケール
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  final _rand = Random();
  late final List<_Dancer> _dancers;

  static const _rainbow = [
    Color(0xFFFF3D78),
    Color(0xFFFF9F1C),
    Color(0xFFFFD54F),
    Color(0xFF4CCF7D),
    Color(0xFF4FA3FF),
    Color(0xFFC084FC),
    Color(0xFFFF3D78),
  ];

  @override
  void initState() {
    super.initState();
    // 虹色のドパガキたちが跳ね回る
    _dancers = List.generate(9, (i) {
      return _Dancer(
        look: Look(
          hair: _rand.nextInt(8),
          hairColor: _rand.nextInt(8),
          skin: _rand.nextInt(5),
          face: _rand.nextInt(3),
          cloth: _rand.nextInt(7),
        ),
        x: 0.05 + _rand.nextDouble() * 0.85,
        y: 0.08 + _rand.nextDouble() * 0.84,
        size: 46 + _rand.nextDouble() * 46,
        phase: _rand.nextDouble(),
        tint: _rainbow[i % _rainbow.length],
      );
    });
  }

  @override
  void dispose() {
    _flow.dispose();
    _quake.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_flow, _quake, _enter]),
        builder: (_, __) {
          final e = Curves.easeOutBack.transform(_enter.value);
          final dx = (_rand.nextDouble() - 0.5) * 7;
          final dy = (_rand.nextDouble() - 0.5) * 7;
          return Stack(
            children: [
              // 背景：回転する虹色の放射
              Positioned.fill(
                child: Transform.rotate(
                  angle: _flow.value * 2 * pi,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        colors: _rainbow
                            .map((c) => c.withValues(alpha: 0.35))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
              // 中央を少し暗くして文字を読ませる
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.9,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
              ),
              // 虹色のドパガキたち
              LayoutBuilder(
                builder: (_, box) => Stack(
                  children: _dancers.map((d) {
                    final t = (_flow.value + d.phase) % 1.0;
                    final bounce = sin(t * 2 * pi) * 16;
                    return Positioned(
                      left: box.maxWidth * d.x - d.size / 2,
                      top: box.maxHeight * d.y - d.size / 2 + bounce,
                      child: Opacity(
                        opacity: (0.55 + sin(t * 2 * pi) * 0.35) * e,
                        child: ColorFiltered(
                          colorFilter:
                              ColorFilter.mode(d.tint, BlendMode.modulate),
                          child: Transform.rotate(
                            angle: sin(t * 2 * pi) * 0.25,
                            child: CharaView(
                                look: d.look, human: 12, dopa: 900, size: d.size),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // 巨大な虹色の文字。揺れ続ける。
              Center(
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: 0.3 + e * 0.7,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _flowingText(widget.text, 58),
                        if (widget.subText != null) ...[
                          const SizedBox(height: 10),
                          _flowingText(widget.subText!, 26),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 虹色が流れ続ける文字
  Widget _flowingText(String text, double size) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment(-1 + _flow.value * 2, 0),
        end: Alignment(1 + _flow.value * 2, 0),
        tileMode: TileMode.repeated,
        colors: _rainbow,
      ).createShader(rect),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 18),
            Shadow(color: Color(0xFFFF3D78), blurRadius: 34),
          ],
        ),
      ),
    );
  }
}

class _Dancer {
  final Look look;
  final double x, y, size, phase;
  final Color tint;
  _Dancer({
    required this.look,
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.tint,
  });
}

// =====================================================================
// 集中線：揃った瞬間に一度だけ走る
// =====================================================================
class FocusLines extends StatefulWidget {
  final Color color;
  const FocusLines({super.key, required this.color});

  @override
  State<FocusLines> createState() => _FocusLinesState();
}

class _FocusLinesState extends State<FocusLines>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _FocusPainter(_c.value, widget.color),
            size: Size.infinite,
          ),
        ),
      );
}

class _FocusPainter extends CustomPainter {
  final double t;
  final Color color;
  _FocusPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.longestSide;
    final p = Paint()
      ..color = color.withValues(alpha: (1 - t) * 0.55)
      ..style = PaintingStyle.stroke;
    final r = Random(11);
    for (var i = 0; i < 44; i++) {
      final a = r.nextDouble() * 2 * pi;
      final inner = maxR * (0.25 + t * 0.7);
      p.strokeWidth = 2 + r.nextDouble() * 6;
      canvas.drawLine(
        center + Offset(cos(a), sin(a)) * inner,
        center + Offset(cos(a), sin(a)) * maxR,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_FocusPainter old) => old.t != t;
}

// =====================================================================
// 連打演出：画面を叩かせる
// =====================================================================
class TapRush extends StatefulWidget {
  final int required;
  final int maxStage; // この回の期待度（0=白〜4=金）。ここまでしか昇格しない。
  final VoidCallback onFilled;

  const TapRush({
    super.key,
    required this.required,
    required this.maxStage,
    required this.onFilled,
  });

  @override
  State<TapRush> createState() => TapRushState();
}

class TapRushState extends State<TapRush> with TickerProviderStateMixin {
  int _count = 0;
  int _stage = 0; // 現在の到達段階
  bool _filled = false;

  // 白→青→緑→赤→金
  static const _stages = [
    Color(0xFFE8E4F0),
    Color(0xFF4FA3FF),
    Color(0xFF4CCF7D),
    Color(0xFFFF3D3D),
    Color(0xFFFFD54F),
  ];
  static const _stageNames = ['', 'チャンス', 'ドパチャンス', '激アツ', '超激アツ'];

  // 小さな叩き反応
  late final AnimationController _tapHit = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 140));
  // 昇格時の演出
  late final AnimationController _promo = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 520));
  final _rand = Random();

  Color get _color => _stages[_stage];

  /// 叩いた回数から到達すべき段階を計算する。
  /// ただし maxStage を超えては上がらない（＝期待度どまり）。
  int _stageForCount(int c) {
    final ratio = c / widget.required;
    final raw = (ratio * 4).floor();
    return raw.clamp(0, widget.maxStage);
  }

  void _tap() {
    if (_filled) return;
    _tapHit.forward(from: 0);
    final next = _count + 1;
    final newStage = _stageForCount(next);
    final promoted = newStage > _stage;
    setState(() {
      _count = next;
      _stage = newStage;
    });
    if (promoted) _promo.forward(from: 0); // 昇格した瞬間だけ光る

    if (_count >= widget.required) {
      _filled = true;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) widget.onFilled();
      });
    }
  }

  @override
  void dispose() {
    _tapHit.dispose();
    _promo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (_count / widget.required).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _tap(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_tapHit, _promo]),
        builder: (context, _) {
          // 昇格の瞬間だけ画面全体を揺らす＋フラッシュ
          final promo = _promo.isAnimating ? (1 - _promo.value) : 0.0;
          final shakeX = (_rand.nextDouble() - 0.5) * promo * 16;
          return Stack(
            children: [
              // フラッシュ
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                      color: _color.withValues(alpha: promo * 0.35)),
                ),
              ),
              Transform.translate(
                offset: Offset(shakeX, 0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5 + ratio * 0.18),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 昇格テロップ
                        SizedBox(
                          height: 30,
                          child: promo > 0 && _stage > 0
                              ? Transform.scale(
                                  scale: 1 + promo * 0.4,
                                  child: Text('${_stageNames[_stage]}！',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: _color,
                                          shadows: const [
                                            Shadow(
                                                color: Colors.black,
                                                blurRadius: 10)
                                          ])),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Transform.scale(
                          scale: 1 + (1 - _tapHit.value) * 0.22 * (_count > 0 ? 1 : 0),
                          child: Text('👆',
                              style: TextStyle(fontSize: 70 + ratio * 22)),
                        ),
                        const SizedBox(height: 14),
                        Text('タップしろ！',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color: _color,
                              shadows: [
                                Shadow(
                                    color: _color.withValues(alpha: 0.6),
                                    blurRadius: 14),
                                const Shadow(color: Colors.black, blurRadius: 10),
                              ],
                            )),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 210,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 12,
                              backgroundColor: const Color(0xFF221A2E),
                              valueColor: AlwaysStoppedAnimation(_color),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('$_count / ${widget.required}',
                            style: TextStyle(
                                fontSize: 13,
                                color: _color,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// ショート動画スワイプ演出
// 縦に積まれた動画を上へ弾いていく。最後の1本で結果が動く。
// =====================================================================
class ShortsSwipe extends StatefulWidget {
  final int required;
  final int maxStage; // 期待度どまり
  final VoidCallback onFilled;

  const ShortsSwipe({
    super.key,
    required this.required,
    required this.maxStage,
    required this.onFilled,
  });

  @override
  State<ShortsSwipe> createState() => ShortsSwipeState();
}

class ShortsSwipeState extends State<ShortsSwipe>
    with TickerProviderStateMixin {
  int _index = 0;
  int _stage = 0;
  bool _filled = false;
  bool _sliding = false;
  final _rand = Random();

  late final AnimationController _slide = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 300));
  late final AnimationController _promo = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _hint = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  static const _stages = [
    Color(0xFFE8E4F0),
    Color(0xFF4FA3FF),
    Color(0xFF4CCF7D),
    Color(0xFFFF3D3D),
    Color(0xFFFFD54F),
  ];
  static const _stageNames = ['', 'チャンス', 'ドパチャンス', '激アツ', '超激アツ'];

  Color get _color => _stages[_stage];

  int _stageFor(int i) =>
      ((i / widget.required) * 4).floor().clamp(0, widget.maxStage);

  Future<void> flick() async {
    if (_filled || _sliding) return;
    _sliding = true;
    await _slide.forward(from: 0);
    if (!mounted) return;
    final next = _index + 1;
    final newStage = _stageFor(next);
    final promoted = newStage > _stage;
    setState(() {
      _index = next;
      _stage = newStage;
    });
    _slide.value = 0;
    _sliding = false;
    if (promoted) _promo.forward(from: 0);
    if (_index >= widget.required) {
      _filled = true;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) widget.onFilled();
      });
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _promo.dispose();
    _hint.dispose();
    super.dispose();
  }

  static const _titles = [
    '【神回】親にバレずにやる方法',
    '知らないと損する裏ワザ',
    '3秒でわかる〇〇',
    '深夜に見るとヤバい動画',
    'これ見た人だけ当たるらしい',
    '寝る前に絶対見るな',
    '衝撃のラスト',
  ];

  Look _lookFor(int i) => Look(
        hair: (i * 3) % 8,
        hairColor: (i * 5) % 8,
        skin: (i * 2) % 5,
        face: i % 3,
        cloth: (i * 4) % 7,
      );

  @override
  Widget build(BuildContext context) {
    final left = widget.required - _index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -60) flick();
      },
      onTap: flick,
      child: AnimatedBuilder(
        animation: Listenable.merge([_slide, _hint, _promo]),
        builder: (context, _) {
          final t = _slide.value;
          final promo = _promo.isAnimating ? (1 - _promo.value) : 0.0;
          final shakeX = (_rand.nextDouble() - 0.5) * promo * 14;
          return Stack(
            children: [
              // 昇格フラッシュ
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                      color: _color.withValues(alpha: promo * 0.32)),
                ),
              ),
              Transform.translate(
                offset: Offset(shakeX, 0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 次の動画
                      Transform.translate(
                        offset: Offset(0, 150 * (1 - t)),
                        child: Opacity(
                          opacity: 0.35 + t * 0.65,
                          child: _videoCard(_index + 1, small: t < 0.5),
                        ),
                      ),
                      // 現在の動画
                      Transform.translate(
                        offset: Offset(0, -560 * Curves.easeIn.transform(t)),
                        child: Opacity(
                          opacity: (1 - t).clamp(0.0, 1.0),
                          child: _videoCard(_index),
                        ),
                      ),
                      // 昇格テロップ
                      if (promo > 0 && _stage > 0)
                        Align(
                          alignment: const Alignment(0, -0.5),
                          child: Transform.scale(
                            scale: 1 + promo * 0.4,
                            child: Text('${_stageNames[_stage]}！',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: _color,
                                    shadows: const [
                                      Shadow(color: Colors.black, blurRadius: 12)
                                    ])),
                          ),
                        ),
                      // ガイド
                      Align(
                        alignment: const Alignment(0, 0.86),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.translate(
                              offset:
                                  Offset(0, -14 * sin(_hint.value * 2 * pi)),
                              child: const Text('👆',
                                  style: TextStyle(fontSize: 34)),
                            ),
                            const SizedBox(height: 4),
                            Text('スワイプしろ！',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: _color,
                                  shadows: [
                                    Shadow(
                                        color: _color.withValues(alpha: 0.6),
                                        blurRadius: 14),
                                    const Shadow(
                                        color: Colors.black, blurRadius: 10),
                                  ],
                                )),
                            const SizedBox(height: 6),
                            Text('あと $left 本',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFFC3A8DD))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _videoCard(int i, {bool small = false}) {
    final title = _titles[i % _titles.length];
    final likes = 1200 + (i * 8377) % 90000;
    return Container(
      width: 210,
      height: 340,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HSVColor.fromAHSV(1, (i * 47) % 360, 0.5, 0.42).toColor(),
            const Color(0xFF120E18),
          ],
        ),
        border: Border.all(color: _color.withValues(alpha: 0.6), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            bottom: 44,
            left: 0,
            right: 0,
            child: Center(
              child: CharaView(
                look: _lookFor(i),
                human: 18,
                dopa: 700,
                size: small ? 92 : 118,
              ),
            ),
          ),
          const Center(
            child: Text('▶',
                style: TextStyle(fontSize: 30, color: Colors.white54)),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black, blurRadius: 6)])),
                const SizedBox(height: 4),
                Text('♥ $likes　💬 ${(likes / 7).round()}',
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0xFFFF9EC2))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// ハズレの余韻：静かに暗くなって、リールだけが残る
// =====================================================================
class LoseAfterglow extends StatefulWidget {
  const LoseAfterglow({super.key});

  @override
  State<LoseAfterglow> createState() => _LoseAfterglowState();
}

class _LoseAfterglowState extends State<LoseAfterglow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = Curves.easeIn.transform(_c.value);
          return Stack(
            children: [
              // ゆっくり色が抜けていく
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: t * 0.55),
                ),
              ),
              // 遅れて出る一言
              if (t > 0.45)
                Align(
                  alignment: const Alignment(0, 0.55),
                  child: Opacity(
                    opacity: ((t - 0.45) / 0.4).clamp(0.0, 1.0),
                    child: const Text(
                      'また今度',
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 4,
                        color: Color(0xFF6B5A8A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// 当たりの余韻：金色の紙吹雪が降り続ける
// =====================================================================
class ConfettiRain extends StatefulWidget {
  const ConfettiRain({super.key});

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  final _rand = Random();
  late final List<_Flake> _flakes = List.generate(46, (i) {
    return _Flake(
      x: _rand.nextDouble(),
      phase: _rand.nextDouble(),
      speed: 0.5 + _rand.nextDouble() * 0.8,
      size: 5 + _rand.nextDouble() * 9,
      sway: 20 + _rand.nextDouble() * 50,
      color: _colors[i % _colors.length],
    );
  });

  static const _colors = [
    Color(0xFFFFD54F),
    Color(0xFFFF9EC2),
    Color(0xFF8FD4FF),
    Color(0xFFB8F0C8),
    Color(0xFFC084FC),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, box) => AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Stack(
            children: _flakes.map((f) {
              final t = ((_c.value * f.speed) + f.phase) % 1.0;
              return Positioned(
                left: box.maxWidth * f.x +
                    sin(t * 4 * pi + f.phase * 6) * f.sway,
                top: box.maxHeight * t - f.size,
                child: Transform.rotate(
                  angle: t * 12 + f.phase * 6,
                  child: Container(
                    width: f.size,
                    height: f.size * 0.6,
                    decoration: BoxDecoration(
                      color: f.color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _Flake {
  final double x, phase, speed, size, sway;
  final Color color;
  _Flake({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.sway,
    required this.color,
  });
}