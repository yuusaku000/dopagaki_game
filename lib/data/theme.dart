import 'package:flutter/material.dart';

/// 画面全体の配色。HTML版の CSS 変数に対応する。
class C {
  static const bg = Color(0xFF120E18);
  static const panel = Color(0xFF1E1826);
  static const panel2 = Color(0xFF261E33);
  static const line = Color(0xFF332A45);
  static const txt = Color(0xFFF0ECF5);
  static const sub = Color(0xFF9A8FAE);

  static const brain = Color(0xFF4FA3FF);
  static const dopa = Color(0xFFFF3D78);
  static const human = Color(0xFF4CCF7D);
  static const warn = Color(0xFFFFC107);
  static const gold = Color(0xFFFFD54F);
  static const sd = Color(0xFFFF9F1C);
}

/// キャラメイクのパーツ
class Parts {
  static const skins = [
    Color(0xFFF6D3BA),
    Color(0xFFE8B894),
    Color(0xFFC98D68),
    Color(0xFF8D5F43),
    Color(0xFFFFE0C9),
  ];
  static const skinNames = ['明るい肌', '標準の肌', '小麦色の肌', '褐色の肌', '色白の肌'];

  static const hairColors = [
    Color(0xFF3B2D2A),
    Color(0xFF141414),
    Color(0xFFA0522D),
    Color(0xFFD9A441),
    Color(0xFFE05A8A),
    Color(0xFF6A8CE0),
    Color(0xFF66C98D),
    Color(0xFFE9E4EF),
  ];
  static const hairColorNames = [
    'ダークブラウン', 'ブラック', 'ブラウン', 'ブロンド',
    'ピンク', 'ブルー', 'グリーン', 'シルバー',
  ];

  static const clothes = [
    Color(0xFF5B4B8A),
    Color(0xFFB03A3A),
    Color(0xFF1F7A4D),
    Color(0xFF2C6FB5),
    Color(0xFFD68910),
    Color(0xFF333340),
    Color(0xFFC2568F),
  ];
  static const clothNames = [
    'パープル', 'レッド', 'グリーン', 'ブルー', 'オレンジ', 'チャコール', 'ローズ',
  ];

  static const hairNames = [
    'ショート', 'ふんわり', 'ツンツン', 'ぱっつん',
    'ロング', 'ツインテール', '坊主', 'アホ毛',
  ];
  static const faceNames = ['丸目', '細目', 'たれ目'];

  static int count(String key) {
    switch (key) {
      case 'hair':
        return hairNames.length;
      case 'hairColor':
        return hairColors.length;
      case 'skin':
        return skins.length;
      case 'face':
        return faceNames.length;
      case 'cloth':
        return clothes.length;
    }
    return 0;
  }

  static const keys = ['hair', 'hairColor', 'skin', 'face', 'cloth'];
  static const keyLabels = {
    'hair': '髪型',
    'hairColor': '髪色',
    'skin': '肌',
    'face': '顔',
    'cloth': '服の色',
  };

  static String nameOf(String key, int i) {
    switch (key) {
      case 'hair':
        return hairNames[i];
      case 'hairColor':
        return hairColorNames[i];
      case 'skin':
        return skinNames[i];
      case 'face':
        return faceNames[i];
      case 'cloth':
        return clothNames[i];
    }
    return '';
  }
}

/// キャラ表示の基準サイズ。用途ごとにここへ集約する。
class CharaSize {
  static const double unit = 36;    // ダンジョンの隊列
  static const double tile = 54;    // 一覧カード
  static const double preview = 90; // ガチャ結果・チュートリアル
  static const double form = 120;   // キャラメイク
  static const double stage = 130;  // 育成画面
  static const double hero = 150;   // ホーム・カットイン
}

/// 育成のルール値
class Rules {
  static const int maxTurn = 36;
  static const List<int> passLines = [80, 150, 230];
  static const int startBrain = 50;
  static const int startDopa = 0;
  static const int startHuman = 70;

  /// 最終スコア = 頭脳×3 + 人間性×5 + ドパ欲×2
  static int score(int brain, int dopa, int human) =>
      brain * 3 + human * 5 + dopa * 2;

  static String rank(int s) {
    if (s > 8000) return 'SS';
    if (s > 6000) return 'S';
    if (s > 4000) return 'A';
    if (s > 2500) return 'B';
    return 'C';
  }
}