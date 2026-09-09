import 'package:flutter/material.dart';

import '../data/theme.dart';
import '../models/dopaminer.dart';

/// キャラクターを図形の組み合わせで描く。画像素材は使わない。
/// human（人間性）で表情が、dopa（ドパ欲）で画面の光が変わる。
class CharaView extends StatelessWidget {
  final Look look;
  final int human;
  final int dopa;
  final double size;

  const CharaView({
    super.key,
    required this.look,
    this.human = 70,
    this.dopa = 0,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 115 / 100, // 元のviewBox比率
      child: CustomPaint(
        painter: _CharaPainter(look: look, human: human, dopa: dopa),
      ),
    );
  }
}

class _CharaPainter extends CustomPainter {
  final Look look;
  final int human;
  final int dopa;

  _CharaPainter({required this.look, required this.human, required this.dopa});

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 100x115 を実サイズにスケール
    final s = size.width / 100;
    canvas.scale(s, s);

    final p = Paint()..style = PaintingStyle.fill;

    // ---- 体 ----
    p.color = Parts.clothes[look.cloth % Parts.clothes.length];
    final body = Path()
      ..moveTo(28, 115)
      ..quadraticBezierTo(28, 83, 50, 83)
      ..quadraticBezierTo(72, 83, 72, 115)
      ..close();
    canvas.drawPath(body, p);

    // ---- スマホ ----
    p.color = const Color(0xFF2B2436);
    final phone = RRect.fromLTRBR(40, 86, 60, 100, const Radius.circular(3));
    canvas.drawRRect(phone, p);
    canvas.drawRRect(
      phone,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF7D6BB0),
    );
    // 画面の光（ドパ欲が高いほど明るい）
    p.color = const Color(0xFF7FD4FF)
        .withValues(alpha: (0.35 + dopa / 700).clamp(0.35, 0.95));
    canvas.drawRRect(
      RRect.fromLTRBR(42.5, 88, 57.5, 98, const Radius.circular(1.5)),
      p,
    );

    // ---- 顔 ----
    p.color = Parts.skins[look.skin % Parts.skins.length];
    canvas.drawOval(const Rect.fromLTRB(23, 23, 77, 81), p);

    // ---- 髪 ----
    p.color = Parts.hairColors[look.hairColor % Parts.hairColors.length];
    canvas.drawPath(_hairPath(look.hair), p);

    // ---- 目 ----
    final face = _faceShape(look.face);
    double ry = face.$2;
    if (human < 25) {
      ry *= 0.5;
    } else if (human < 50) {
      ry *= 0.78;
    }
    p.color = const Color(0xFF241A16);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(39, 53), width: face.$1 * 2, height: ry * 2), p);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(61, 53), width: face.$1 * 2, height: ry * 2), p);

    // 目のハイライト（人間性が下がると消える）
    final gleam = human < 40 ? 0.0 : (human < 60 ? 0.4 : 1.0);
    if (gleam > 0) {
      p.color = Colors.white.withValues(alpha: gleam);
      canvas.drawCircle(const Offset(40.8, 50.6), 1.9, p);
      canvas.drawCircle(const Offset(62.8, 50.6), 1.9, p);
    }

    // ---- 口 ----
    final mouth = Path();
    if (human < 35) {
      mouth
        ..moveTo(44, 68)
        ..quadraticBezierTo(50, 64, 56, 68);
    } else {
      mouth
        ..moveTo(44, 66)
        ..quadraticBezierTo(50, 71, 56, 66);
    }
    canvas.drawPath(
      mouth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFA8705A),
    );

    // ---- 隈 ----
    if (human < 50) {
      final dark = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF8A6BA0);
      canvas.drawPath(
        Path()
          ..moveTo(34, 60)
          ..quadraticBezierTo(39, 63, 44, 60),
        dark,
      );
      canvas.drawPath(
        Path()
          ..moveTo(56, 60)
          ..quadraticBezierTo(61, 63, 66, 60),
        dark,
      );
    }
  }

  /// (rx, ry)
  (double, double) _faceShape(int i) {
    switch (i % 3) {
      case 1:
        return (5.6, 3.2);
      case 2:
        return (4.2, 7.5);
      default:
        return (5.0, 6.5);
    }
  }

  Path _hairPath(int i) {
    final p = Path();
    switch (i % 8) {
      case 1: // ふんわり
        p
          ..moveTo(20, 52)
          ..quadraticBezierTo(20, 18, 50, 18)
          ..quadraticBezierTo(80, 18, 80, 52)
          ..quadraticBezierTo(76, 46, 71, 48)
          ..quadraticBezierTo(68, 32, 50, 32)
          ..quadraticBezierTo(32, 32, 29, 48)
          ..quadraticBezierTo(24, 46, 20, 52)
          ..close();
      case 2: // ツンツン
        p
          ..moveTo(22, 46)
          ..quadraticBezierTo(26, 18, 50, 18)
          ..quadraticBezierTo(74, 18, 78, 46)
          ..quadraticBezierTo(75, 40, 70, 41)
          ..lineTo(68, 32)
          ..lineTo(60, 40)
          ..lineTo(54, 31)
          ..lineTo(48, 40)
          ..lineTo(40, 32)
          ..lineTo(38, 41)
          ..quadraticBezierTo(33, 40, 30, 45)
          ..close();
      case 3: // ぱっつん（前髪がまっすぐ）
        p
          ..moveTo(21, 50)
          ..quadraticBezierTo(21, 17, 50, 17)
          ..quadraticBezierTo(79, 17, 79, 50)
          ..lineTo(79, 44)
          ..lineTo(21, 44)
          ..close();
      case 4: // ロング（横に長く垂れる）
        p
          ..moveTo(19, 78)
          ..quadraticBezierTo(17, 20, 50, 17)
          ..quadraticBezierTo(83, 20, 81, 78)
          ..quadraticBezierTo(79, 58, 73, 50)
          ..quadraticBezierTo(70, 33, 50, 33)
          ..quadraticBezierTo(30, 33, 27, 50)
          ..quadraticBezierTo(21, 58, 19, 78)
          ..close();
      case 5: // ツインテール
        p
          ..moveTo(22, 48)
          ..quadraticBezierTo(24, 18, 50, 18)
          ..quadraticBezierTo(76, 18, 78, 48)
          ..quadraticBezierTo(72, 35, 50, 35)
          ..quadraticBezierTo(28, 35, 22, 48)
          ..close();
        // 左右の房
        p.addOval(
            Rect.fromCenter(center: const Offset(18, 58), width: 15, height: 30));
        p.addOval(
            Rect.fromCenter(center: const Offset(82, 58), width: 15, height: 30));
      case 6: // 坊主（地肌が透ける短さ）
        p
          ..moveTo(25, 45)
          ..quadraticBezierTo(27, 24, 50, 24)
          ..quadraticBezierTo(73, 24, 75, 45)
          ..quadraticBezierTo(70, 38, 50, 38)
          ..quadraticBezierTo(30, 38, 25, 45)
          ..close();
      case 7: // アホ毛（1本跳ねる）
        p
          ..moveTo(22, 48)
          ..quadraticBezierTo(24, 18, 50, 18)
          ..quadraticBezierTo(76, 18, 78, 48)
          ..quadraticBezierTo(72, 35, 50, 35)
          ..quadraticBezierTo(28, 35, 22, 48)
          ..close();
        p
          ..moveTo(48, 20)
          ..quadraticBezierTo(50, 4, 62, 6)
          ..quadraticBezierTo(54, 10, 53, 21)
          ..close();
      default: // ショート
        p
          ..moveTo(22, 48)
          ..quadraticBezierTo(24, 18, 50, 18)
          ..quadraticBezierTo(76, 18, 78, 48)
          ..quadraticBezierTo(72, 35, 50, 35)
          ..quadraticBezierTo(28, 35, 22, 48)
          ..close();
    }
    return p;
  }

  @override
  bool shouldRepaint(_CharaPainter old) =>
      old.human != human ||
      old.dopa != dopa ||
      old.look.hair != look.hair ||
      old.look.hairColor != look.hairColor ||
      old.look.skin != look.skin ||
      old.look.face != look.face ||
      old.look.cloth != look.cloth;
}