/// キャラクターの外見。各値はパーツ配列のインデックス。
class Look {
  int hair;
  int hairColor;
  int skin;
  int face;
  int cloth;

  Look({
    this.hair = 0,
    this.hairColor = 0,
    this.skin = 0,
    this.face = 0,
    this.cloth = 0,
  });

  Look copy() => Look(
        hair: hair,
        hairColor: hairColor,
        skin: skin,
        face: face,
        cloth: cloth,
      );

  Map<String, dynamic> toJson() => {
        'hair': hair,
        'hairColor': hairColor,
        'skin': skin,
        'face': face,
        'cloth': cloth,
      };

  factory Look.fromJson(Map<String, dynamic> j) => Look(
        hair: j['hair'] ?? 0,
        hairColor: j['hairColor'] ?? 0,
        skin: j['skin'] ?? 0,
        face: j['face'] ?? 0,
        cloth: j['cloth'] ?? 0,
      );
}

/// 育成を終えたドパガキ。次回以降のお供として選べる。
class Dopaminer {
  final String name;
  final Look look;
  final int brain;
  final int dopa;
  final int human;
  final int score;
  final String rank;

  /// 育成中によく使ったカード2枚。次の育成の抽選に追加される。
  final List<String> cards;

  /// 初期配布キャラかどうか
  final bool seed;

  Dopaminer({
    required this.name,
    required this.look,
    required this.brain,
    required this.dopa,
    required this.human,
    required this.score,
    required this.rank,
    required this.cards,
    this.seed = false,
  });

  /// ダンジョンでの戦闘力（人間性は一切関与しない）
  int get atk => (dopa / 12).round().clamp(1, 9999);
  double get rate => (brain / 60).clamp(0.15, 10.0);
  int get maxHp => (dopa * 0.6 + brain).round();

  Map<String, dynamic> toJson() => {
        'name': name,
        'look': look.toJson(),
        'brain': brain,
        'dopa': dopa,
        'human': human,
        'score': score,
        'rank': rank,
        'cards': cards,
        'seed': seed,
      };

  factory Dopaminer.fromJson(Map<String, dynamic> j) => Dopaminer(
        name: j['name'] ?? '???',
        look: Look.fromJson(Map<String, dynamic>.from(j['look'] ?? {})),
        brain: j['brain'] ?? 0,
        dopa: j['dopa'] ?? 0,
        human: j['human'] ?? 0,
        score: j['score'] ?? 0,
        rank: j['rank'] ?? 'C',
        cards: List<String>.from(j['cards'] ?? const []),
        seed: j['seed'] ?? false,
      );
}

/// D12枚 + SD4枚のデッキ
class Deck {
  String name;
  List<String> d;
  List<String> sd;

  Deck({required this.name, required this.d, required this.sd});

  static const int maxD = 12;
  static const int maxSd = 4;
  static const int maxCopy = 3;

  bool get isComplete => d.length == maxD && sd.length == maxSd;

  Map<String, dynamic> toJson() => {'name': name, 'd': d, 'sd': sd};

  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
        name: j['name'] ?? 'デッキ',
        d: List<String>.from(j['d'] ?? const []),
        sd: List<String>.from(j['sd'] ?? const []),
      );

  static Deck defaults(int n) => Deck(
        name: 'デッキ$n',
        d: [
          'short', 'short', 'short',
          'juku', 'juku', 'juku',
          'study', 'study',
          'sleep', 'play', 'meal', 'soc',
        ],
        sd: ['game', 'game', 'kf', 'ke'],
      );
}