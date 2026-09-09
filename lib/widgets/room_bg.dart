import 'dart:math';

import 'package:flutter/material.dart';

/// 育成画面の背景。季節で窓の外と壁の色が変わる子供部屋。
class RoomBackground extends StatelessWidget {
  final String season;
  const RoomBackground({super.key, required this.season});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RoomPainter(season),
      size: Size.infinite,
    );
  }
}

class _Palette {
  final Color wall, skyTop, skyBottom, accent, floor;
  const _Palette(this.wall, this.skyTop, this.skyBottom, this.accent, this.floor);
}

const _palettes = {
  'spring': _Palette(Color(0xFF463052), Color(0xFF8FB8E8), Color(0xFFDFE9F5),
      Color(0xFFF2A3C7), Color(0xFF2C2036)),
  'summer': _Palette(Color(0xFF1F3A55), Color(0xFF4FA8E0), Color(0xFFBFE6FF),
      Color(0xFFFFE07A), Color(0xFF182838)),
  'autumn': _Palette(Color(0xFF4A3020), Color(0xFFE08A4A), Color(0xFFFFD8A8),
      Color(0xFFE05A2A), Color(0xFF2C2018)),
  'winter': _Palette(Color(0xFF22334A), Color(0xFF5A7EA8), Color(0xFFC8DBEF),
      Color(0xFFE8F4FF), Color(0xFF182230)),
  'xmas': _Palette(Color(0xFF1B3A2C), Color(0xFF2A4A6A), Color(0xFF12203A),
      Color(0xFFE04A4A), Color(0xFF14241C)),
  'exam': _Palette(Color(0xFF3A3944), Color(0xFF6A6A78), Color(0xFFC8C8D4),
      Color(0xFFC0C0CC), Color(0xFF22222C)),
};

class _RoomPainter extends CustomPainter {
  final String season;
  _RoomPainter(this.season);

  @override
  void paint(Canvas canvas, Size size) {
    final pal = _palettes[season] ?? _palettes['spring']!;
    // 元の座標系 400x300 に合わせてスケール
    final sx = size.width / 400, sy = size.height / 300;
    canvas.save();
    canvas.scale(sx, sy);

    final p = Paint();

    // ---- 壁 ----
    p.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [pal.wall, const Color(0xFF171122)],
    ).createShader(const Rect.fromLTWH(0, 0, 400, 300));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 300), p);
    p.shader = null;

    // ---- 窓の空 ----
    const win = Rect.fromLTWH(228, 34, 128, 102);
    p.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [pal.skyTop, pal.skyBottom],
    ).createShader(win);
    canvas.drawRRect(RRect.fromRectXY(win, 5, 5), p);
    p.shader = null;

    canvas.save();
    canvas.clipRRect(RRect.fromRectXY(win, 5, 5));
    _drawSeasonScene(canvas, pal);
    canvas.restore();

    // ---- 窓枠 ----
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = const Color(0xFF0F0B16);
    canvas.drawRRect(RRect.fromRectXY(win, 5, 5), frame);
    p.color = const Color(0xFF0F0B16);
    canvas.drawRect(const Rect.fromLTWH(290, 34, 5, 102), p);
    canvas.drawRect(const Rect.fromLTWH(228, 82, 128, 5), p);

    // ---- 本棚 ----
    p.color = const Color(0xFF241A2E);
    canvas.drawRRect(
        RRect.fromRectXY(const Rect.fromLTWH(18, 52, 86, 130), 4, 4), p);
    const bookColors = [
      Color(0xFFC25A7A), Color(0xFF5A7EC2), Color(0xFFC2A35A), Color(0xFF5AC292)
    ];
    for (var i = 0; i < 11; i++) {
      p.color = bookColors[i % 4].withValues(alpha: 0.8);
      canvas.drawRect(
          Rect.fromLTWH(24 + i * 7, 60 + (i % 3) * 3, 5, 34 - (i % 3) * 3), p);
    }
    p.color = const Color(0xFF171122);
    canvas.drawRect(const Rect.fromLTWH(18, 100, 86, 5), p);
    const bookColors2 = [
      Color(0xFF8A6BB0), Color(0xFFB06B8A), Color(0xFF6BB08A), Color(0xFFB0A06B)
    ];
    for (var i = 0; i < 9; i++) {
      p.color = bookColors2[i % 4].withValues(alpha: 0.7);
      canvas.drawRect(
          Rect.fromLTWH(26 + i * 8, 110 + (i % 2) * 4, 6, 30 - (i % 2) * 4), p);
    }
    p.color = const Color(0xFF171122);
    canvas.drawRect(const Rect.fromLTWH(18, 150, 86, 5), p);

    // ---- ポスター ----
    p.color = const Color(0xFF2C2038);
    canvas.drawRRect(
        RRect.fromRectXY(const Rect.fromLTWH(130, 52, 66, 48), 3, 3), p);
    canvas.drawRRect(
      RRect.fromRectXY(const Rect.fromLTWH(130, 52, 66, 48), 3, 3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF453256),
    );
    p.color = pal.accent.withValues(alpha: 0.8);
    canvas.drawCircle(const Offset(163, 72), 11, p);
    p.color = const Color(0xFF453256);
    canvas.drawRRect(
        RRect.fromRectXY(const Rect.fromLTWH(142, 88, 42, 4), 2, 2), p);

    // ---- クリスマスツリー ----
    if (season == 'xmas') {
      p.color = const Color(0xFF1F6A44);
      canvas.drawPath(
          Path()
            ..moveTo(370, 210)
            ..lineTo(386, 244)
            ..lineTo(354, 244)
            ..close(),
          p);
      p.color = const Color(0xFF28855A);
      canvas.drawPath(
          Path()
            ..moveTo(370, 188)
            ..lineTo(383, 216)
            ..lineTo(357, 216)
            ..close(),
          p);
      p.color = const Color(0xFF5A3F2A);
      canvas.drawRect(const Rect.fromLTWH(366, 244, 8, 10), p);
      p.color = const Color(0xFFFFD54F);
      canvas.drawCircle(const Offset(370, 184), 4, p);
    }

    // ---- 床 ----
    p.color = pal.floor;
    canvas.drawRect(const Rect.fromLTWH(0, 182, 400, 118), p);
    p.color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(const Rect.fromLTWH(0, 182, 400, 8), p);
    p.color = Colors.black.withValues(alpha: 0.14);
    for (var i = 0; i < 7; i++) {
      canvas.drawRect(Rect.fromLTWH(0, 196 + i * 15, 400, 1.5), p);
    }

    // ---- 机 ----
    p.color = const Color(0xFF3A2A48);
    canvas.drawRRect(
        RRect.fromRectXY(const Rect.fromLTWH(248, 176, 132, 9), 3, 3), p);
    p.color = const Color(0xFF2C2038);
    canvas.drawRect(const Rect.fromLTWH(256, 185, 8, 42), p);
    canvas.drawRect(const Rect.fromLTWH(364, 185, 8, 42), p);

    canvas.restore();
  }

  /// 窓の外の季節表現
  void _drawSeasonScene(Canvas canvas, _Palette pal) {
    final p = Paint();
    switch (season) {
      case 'summer':
        p.color = const Color(0xFFFFF6B0);
        canvas.drawCircle(const Offset(332, 62), 15, p);
        p.color = Colors.white.withValues(alpha: 0.85);
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(268, 66), width: 52, height: 26), p);
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(286, 60), width: 36, height: 22), p);
        break;
      case 'spring':
        p.color = pal.accent.withValues(alpha: 0.85);
        canvas.drawCircle(const Offset(262, 104), 20, p);
        p.color = pal.accent.withValues(alpha: 0.7);
        canvas.drawCircle(const Offset(288, 112), 15, p);
        p.color = const Color(0xFF5A3F2A);
        canvas.drawRect(const Rect.fromLTWH(258, 112, 6, 24), p);
        break;
      case 'autumn':
        p.color = pal.accent.withValues(alpha: 0.85);
        canvas.drawCircle(const Offset(270, 106), 21, p);
        p.color = const Color(0xFF4A3320);
        canvas.drawRect(const Rect.fromLTWH(266, 112, 7, 24), p);
        p.color = pal.accent;
        canvas.drawCircle(const Offset(316, 120), 4, p);
        canvas.drawCircle(const Offset(336, 106), 3.5, p);
        break;
      case 'winter':
      case 'xmas':
        p.color = Colors.white.withValues(alpha: 0.85);
        final r = Random(7);
        for (var i = 0; i < 16; i++) {
          canvas.drawCircle(
            Offset(234 + r.nextDouble() * 118, 40 + r.nextDouble() * 92),
            2.4,
            p,
          );
        }
        break;
      case 'exam':
        p.color = const Color(0xFF7A7A88).withValues(alpha: 0.35);
        canvas.drawRect(const Rect.fromLTWH(228, 34, 128, 102), p);
        break;
    }
  }

  @override
  bool shouldRepaint(_RoomPainter old) => old.season != season;
}