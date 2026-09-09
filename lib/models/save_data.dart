import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cards.dart';
import 'card.dart';
import 'dopaminer.dart';

/// 設定項目
class Settings {
  bool showEffect; // カード効果を数値で表示
  bool showLine; // セリフを表示
  bool anim; // 演出

  Settings({this.showEffect = true, this.showLine = true, this.anim = true});

  Map<String, dynamic> toJson() =>
      {'showEffect': showEffect, 'showLine': showLine, 'anim': anim};

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        showEffect: j['showEffect'] ?? true,
        showLine: j['showLine'] ?? true,
        anim: j['anim'] ?? true,
      );
}

/// アプリ全体の状態。ChangeNotifier なので画面から listen できる。
class SaveData extends ChangeNotifier {
  static const String _key = 'dopagaki_save_v1';

  List<Dopaminer> dopaminers = [];
  List<Deck> decks = [];
  int activeDeck = 0;
  int tickets = 5;
  int fragments = 0;
  int bestFloor = 0;

  /// SDカードの所持。1枚でも持っていればデッキに3枚まで積める。
  Set<String> ownedSd = {};

  /// 解放済みのキャラメイクパーツ
  Map<String, Set<int>> parts = {};

  Settings settings = Settings();

  // ---------- 初期状態 ----------
  void _applyDefaults() {
    decks = [Deck.defaults(1), Deck.defaults(2), Deck.defaults(3)];
    ownedSd = {'game', 'kf', 'ke'};
    parts = {
      'hair': {0, 1},
      'hairColor': {0, 1, 2},
      'skin': {0, 1},
      'face': {0, 1},
      'cloth': {0, 1, 2},
    };
    dopaminers = _seedDopaminers();
  }

  static List<Dopaminer> _seedDopaminers() {
    List<Dopaminer> make(String name, Look look, int b, int d, int h,
        List<String> cards) {
      final score = b * 3 + h * 5 + d * 2;
      return [
        Dopaminer(
          name: name,
          look: look,
          brain: b,
          dopa: d,
          human: h,
          score: score,
          rank: 'C',
          cards: cards,
          seed: true,
        )
      ];
    }

    return [
      ...make('ドパオ', Look(hair: 0, hairColor: 0, skin: 0, face: 0, cloth: 0),
          96, 420, 44, ['short', 'study']),
      ...make('ドパ美', Look(hair: 1, hairColor: 4, skin: 4, face: 2, cloth: 6),
          78, 510, 31, ['sns', 'meal']),
      ...make('ドパゾー', Look(hair: 2, hairColor: 2, skin: 2, face: 1, cloth: 1),
          120, 365, 52, ['juku', 'soc']),
      ...make('ドパリン', Look(hair: 0, hairColor: 5, skin: 1, face: 2, cloth: 3),
          64, 588, 22, ['tv', 'sleep']),
    ];
  }

  // ---------- 読み書き ----------
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _applyDefaults();
      await save();
      notifyListeners();
      return;
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      dopaminers = (j['dopaminers'] as List? ?? [])
          .map((e) => Dopaminer.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      decks = (j['decks'] as List? ?? [])
          .map((e) => Deck.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (decks.isEmpty) {
        decks = [Deck.defaults(1), Deck.defaults(2), Deck.defaults(3)];
      }
      activeDeck = j['activeDeck'] ?? 0;
      tickets = j['tickets'] ?? 5;
      fragments = j['fragments'] ?? 0;
      bestFloor = j['bestFloor'] ?? 0;
      ownedSd = Set<String>.from(j['ownedSd'] ?? const []);
      parts = (j['parts'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, Set<int>.from(v as List)),
      );
      if (parts.isEmpty) {
        parts = {
          'hair': {0, 1},
          'hairColor': {0, 1, 2},
          'skin': {0, 1},
          'face': {0, 1},
          'cloth': {0, 1, 2},
        };
      }
      settings =
          Settings.fromJson(Map<String, dynamic>.from(j['settings'] ?? {}));
    } catch (_) {
      // 壊れていたら初期状態に戻す
      _applyDefaults();
    }
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final j = {
      'dopaminers': dopaminers.map((e) => e.toJson()).toList(),
      'decks': decks.map((e) => e.toJson()).toList(),
      'activeDeck': activeDeck,
      'tickets': tickets,
      'fragments': fragments,
      'bestFloor': bestFloor,
      'ownedSd': ownedSd.toList(),
      'parts': parts.map((k, v) => MapEntry(k, v.toList())),
      'settings': settings.toJson(),
    };
    await prefs.setString(_key, jsonEncode(j));
  }

  Future<void> wipe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _applyDefaults();
    tickets = 5;
    fragments = 0;
    bestFloor = 0;
    activeDeck = 0;
    settings = Settings();
    await save();
    notifyListeners();
  }

  /// 変更を保存して画面に通知する共通処理
  Future<void> commit() async {
    await save();
    notifyListeners();
  }

  // ---------- 便利メソッド ----------
  Deck get deck => decks[activeDeck.clamp(0, decks.length - 1)];

  /// 同名を何枚まで積めるか。Dは常に3枚、SDは所持していれば3枚。
  int copyLimit(GameCard c) =>
      c.rarity == Rarity.d ? Deck.maxCopy : (ownedSd.contains(c.id) ? Deck.maxCopy : 0);

  bool isPartUnlocked(String key, int index) =>
      parts[key]?.contains(index) ?? false;

  int get bestScore =>
      dopaminers.isEmpty ? 0 : dopaminers.map((d) => d.score).reduce((a, b) => a > b ? a : b);

  List<GameCard> get ownedSdCards =>
      cardsOf(Rarity.sd).where((c) => ownedSd.contains(c.id)).toList();
}