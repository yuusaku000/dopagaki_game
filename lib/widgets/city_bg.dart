import 'dart:math';

import 'package:flutter/material.dart';

/// ホーム画面の背景。深夜の街並みと、灯りのついた窓。
class NightCityBackground extends StatelessWidget {
  const NightCityBackground({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CityPainter(), size: Size.infinite);
}

class _CityPainter extends CustomPainter {
  // 建物の輪郭（元の座標系 400x560）
  static const _skyline = [
    [0.0, 300.0], [34.0, 300.0], [34.0, 264.0], [74.0, 264.0], [74.0, 318.0],
    [110.0, 318.0], [110.0, 244.0], [150.0, 244.0], [150.0, 300.0],
    [192.0, 300.0], [192.0, 216.0], [236.0, 216.0], [236.0, 288.0],
    [272.0, 288.0], [272.0, 252.0], [316.0, 252.0], [316.0, 312.0],
    [354.0, 312.0], [354.0, 276.0], [400.0, 276.0],
  ];

  // 窓の位置
  static const _windows = [
    [12.0, 312.0], [44.0, 286.0], [52.0, 330.0], [84.0, 286.0], [92.0, 332.0],
    [118.0, 268.0], [126.0, 300.0], [158.0, 268.0], [166.0, 322.0],
    [200.0, 240.0], [208.0, 276.0], [216.0, 308.0], [244.0, 238.0],
    [252.0, 272.0], [280.0, 272.0], [288.0, 306.0], [324.0, 276.0],
    [332.0, 300.0], [364.0, 296.0], [372.0, 330.0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 400, sy = size.height / 560;
    canvas.save();
    canvas.scale(sx, sy);

    final p = Paint();
    const full = Rect.fromLTWH(0, 0, 400, 560);

    // ---- 空 ----
    p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF3D1E57), Color(0xFF241636), Color(0xFF120E18)],
      stops: [0.0, 0.55, 1.0],
    ).createShader(full);
    canvas.drawRect(full, p);
    p.shader = null;

    // ---- 星 ----
    for (var i = 0; i < 40; i++) {
      final x = (i * 97) % 400.0;
      final y = (i * 61) % 230.0;
      p.color = Colors.white.withValues(alpha: 0.15 + (i % 5) * 0.12);
      canvas.drawCircle(Offset(x, y), i % 7 == 0 ? 1.6 : 1.0, p);
    }

    // ---- 月 ----
    p.shader = const RadialGradient(
      colors: [Color(0xFFFFF3D0), Color(0x00FFF3D0)],
    ).createShader(Rect.fromCircle(center: const Offset(316, 82), radius: 66));
    canvas.drawCircle(const Offset(316, 82), 66, p);
    p.shader = null;
    p.color = const Color(0xFFFFF6DD).withValues(alpha: 0.92);
    canvas.drawCircle(const Offset(316, 82), 27, p);
    p.color = const Color(0xFFE8D9B4).withValues(alpha: 0.55);
    canvas.drawCircle(const Offset(306, 74), 5, p);
    p.color = const Color(0xFFE8D9B4).withValues(alpha: 0.45);
    canvas.drawCircle(const Offset(324, 92), 3.5, p);

    // ---- ビル群 ----
    final city = Path()..moveTo(0, 372);
    for (final pt in _skyline) {
      city.lineTo(pt[0], pt[1]);
    }
    city
      ..lineTo(400, 372)
      ..close();
    p.color = const Color(0xFF150F22);
    canvas.drawPath(city, p);

    // ---- 窓明かり ----
    for (var i = 0; i < 56; i++) {
      final w = _windows[i % _windows.length];
      // 同じ座標が重ならないよう少しずらす
      final ox = (i ~/ _windows.length) * 11.0;
      p.color = (i % 4 == 0 ? const Color(0xFF8FD4FF) : const Color(0xFFFFD98A))
          .withValues(alpha: 0.25 + (i % 5) * 0.13);
      canvas.drawRect(Rect.fromLTWH(w[0] + ox, w[1], 7, 9), p);
    }

    // ---- 地面 ----
    p.color = const Color(0xFF100C18);
    canvas.drawRect(const Rect.fromLTWH(0, 372, 400, 188), p);
    p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00FF3D78), Color(0x47FF3D78)],
    ).createShader(const Rect.fromLTWH(0, 372, 400, 188));
    canvas.drawRect(const Rect.fromLTWH(0, 372, 400, 188), p);
    p.shader = null;

    p.color = const Color(0xFF1C1428).withValues(alpha: 0.9);
    canvas.drawPath(
      Path()
        ..moveTo(0, 372)
        ..quadraticBezierTo(200, 356, 400, 372)
        ..lineTo(400, 396)
        ..quadraticBezierTo(200, 380, 0, 396)
        ..close(),
      p,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CityPainter oldDelegate) => false;
}

/// ゆっくり流れる星の瞬き。背景に少しだけ動きを足す。
class TwinkleLayer extends StatefulWidget {
  const TwinkleLayer({super.key});

  @override
  State<TwinkleLayer> createState() => _TwinkleLayerState();
}

class _TwinkleLayerState extends State<TwinkleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) =>
            CustomPaint(painter: _TwinklePainter(_c.value), size: Size.infinite),
      );
}

class _TwinklePainter extends CustomPainter {
  final double t;
  _TwinklePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final r = Random(3);
    for (var i = 0; i < 14; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height * 0.4;
      final phase = (t + i / 14) % 1.0;
      final a = (sin(phase * 2 * pi) * 0.5 + 0.5) * 0.6;
      p.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), 1.4, p);
    }
  }

  @override
  bool shouldRepaint(_TwinklePainter old) => old.t != t;
}