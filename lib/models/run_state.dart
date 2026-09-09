import 'dart:math';

import '../data/cards.dart';
import '../data/theme.dart';
import '../models/card.dart';
import '../models/dopaminer.dart';
import '../models/save_data.dart';

/// カードを選んだ結果の差分。演出に使う。
class TurnResult {
  final int brain;
  final int dopa;
  final int human;
  final String line;
  final bool testTurn;
  final bool passed;
  final String? notice;

  TurnResult({
    required this.brain,
    required this.dopa,
    required this.human,
    required this.line,
    this.testTurn = false,
    this.passed = false,
    this.notice,
  });
}

/// 36ターンの育成を管理する。UIを持たない純粋なロジック。
class RunState {
  final String name;
  final Look look;

  int turn = 1;
  int brain = Rules.startBrain;
  int dopa = Rules.startDopa;
  int human = Rules.startHuman;
  double multiplier = 1.0;

  /// SD枠の解禁数。4年テスト合格で2、5年テスト合格で4。
  int sdUnlocked = 0;

  /// 抽選の山
  final List<String> deckD;
  final List<String> deckSd;
  final List<String> extraCards; // ドパミナー由来

  /// カードの使用回数（継承カードの決定に使う）
  final Map<String, int> used = {};

  final _rand = Random();
  List<GameCard> hand = [];

  RunState({
    required this.name,
    required this.look,
    required this.deckD,
    required this.deckSd,
    required this.extraCards,
    int brainBonus = 0,
    int dopaBonus = 0,
    int humanBonus = 0,
  }) {
    brain += brainBonus;
    dopa += dopaBonus;
    human = (human + humanBonus).clamp(0, 100);
    draw();
  }

  /// ドパミナーを連れて行く場合のボーナス込みで生成する
  factory RunState.start({
    required String name,
    required Look look,
    required Deck deck,
    required List<Dopaminer> partners,
  }) {
    int b = 0, d = 0, h = 0;
    final extra = <String>[];
    for (final p in partners) {
      b += (p.brain / 20).round();
      d += (p.dopa / 40).round();
      h += (p.human / 20).round();
      extra.addAll(p.cards);
    }
    return RunState(
      name: name,
      look: look,
      deckD: List.of(deck.d),
      deckSd: List.of(deck.sd),
      extraCards: extra,
      brainBonus: b,
      dopaBonus: d,
      humanBonus: h,
    );
  }

  // ---------- 暦 ----------
  int get grade => 4 + ((turn - 1) ~/ 12);
  int get month {
    final m = ((turn - 1) % 12) + 4;
    return m > 12 ? m - 12 : m;
  }

  String get dateLabel => '小$grade $month月';
  bool get isTestTurn => turn % 12 == 0;
  int get passLine => Rules.passLines[((turn - 1) ~/ 12).clamp(0, 2)];

  /// 背景に使う季節キー
  String get season {
    if (isTestTurn) return 'exam';
    if (month == 12) return 'xmas';
    if (month == 8) return 'summer';
    if (month <= 6) return 'spring';
    if (month <= 9) return 'summer';
    if (month <= 11) return 'autumn';
    return 'winter';
  }

  String? get eventLabel {
    if (isTestTurn) return '📝 学年末テスト';
    if (month == 8) return '☀ 夏休み';
    if (month == 12) return '🎄 クリスマス';
    return null;
  }

  bool get isOver => turn > Rules.maxTurn || human <= 0;
  bool get failed => human <= 0;

  // ---------- 抽選 ----------
  /// デッキ16枚 + 解禁済みSD + ドパミナー分から3枚を引く
  void draw() {
    final pile = <String>[
      ...deckD,
      ...deckSd.take(sdUnlocked),
      ...extraCards,
    ];
    if (pile.isEmpty) pile.addAll(deckD);

    final picked = <GameCard>[];
    var guard = 0;
    while (picked.length < 3 && guard++ < 300) {
      final id = pile[_rand.nextInt(pile.length)];
      if (picked.any((c) => c.id == id)) continue;
      picked.add(cardById(id));
    }
    // 山の種類が3未満だった場合の保険
    if (picked.length < 3) {
      for (final c in kCards) {
        if (picked.length >= 3) break;
        if (!picked.any((x) => x.id == c.id)) picked.add(c);
      }
    }
    hand = picked;
  }

  bool isFromPartner(GameCard c) =>
      extraCards.contains(c.id) &&
      !deckD.contains(c.id) &&
      !deckSd.contains(c.id);

  // ---------- 1ターン進める ----------
  TurnResult choose(GameCard c) {
    final gain = (c.dopa * multiplier).round();
    brain = (brain + c.brain).clamp(0, 99999);
    dopa = (dopa + gain).clamp(0, 999999);
    human = (human + c.human).clamp(0, 100);
    used[c.id] = (used[c.id] ?? 0) + 1;

    // 人間性が下がりきるとセリフが崩壊する
    const hollow = ['……', 'べつに', 'なんでもいいよ', '疲れた'];
    final pool = human < 30 ? hollow : c.lines;
    var line = pool[_rand.nextInt(pool.length)];

    var test = false, passed = false;
    String? notice;
    if (isTestTurn) {
      test = true;
      if (brain >= passLine) {
        passed = true;
        multiplier = double.parse((multiplier * 1.1).toStringAsFixed(2));
        if (turn == 12) {
          sdUnlocked = 2;
          notice = '合格！ ゲーム機を買ってもらえた（SD枠 2枚 解禁）';
        } else if (turn == 24) {
          sdUnlocked = 4;
          notice = '合格！ エナドリ解禁（SD枠 すべて開放）';
        } else {
          notice = '全部受かったぞ';
        }
        line = notice;
      } else {
        notice = 'テスト、ダメだった…';
        line = notice;
      }
    }

    turn++;
    if (!isOver) draw();

    return TurnResult(
      brain: c.brain,
      dopa: gain,
      human: c.human,
      line: line,
      testTurn: test,
      passed: passed,
      notice: notice,
    );
  }

  // ---------- 結果 ----------
  int get finalScore => failed ? 0 : Rules.score(brain, dopa, human);
  String get finalRank => failed ? '圏外' : Rules.rank(finalScore);

  /// よく使ったカード上位2枚を継承する
  List<String> get inheritedCards {
    final e = used.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final r = e.take(2).map((x) => x.key).toList();
    return r.isEmpty ? ['short'] : r;
  }

  Dopaminer toDopaminer() => Dopaminer(
        name: name,
        look: look,
        brain: brain,
        dopa: dopa,
        human: human,
        score: finalScore,
        rank: finalRank,
        cards: inheritedCards,
      );
}