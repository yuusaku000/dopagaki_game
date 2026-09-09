/// カードのレアリティ
enum Rarity { d, sd }

extension RarityLabel on Rarity {
  String get label => this == Rarity.d ? 'D' : 'SD';
}

/// 育成中に選ぶカード1枚分の定義。
/// 定義はすべて定数なので、セーブデータには id だけを保存する。
class GameCard {
  final String id;
  final Rarity rarity;
  final String title;
  final String desc;

  /// ステータス増減
  final int brain; // 頭脳
  final int dopa; // ドパ欲
  final int human; // 人間性

  /// 選んだときのセリフ候補
  final List<String> lines;

  const GameCard({
    required this.id,
    required this.rarity,
    required this.title,
    required this.desc,
    required this.brain,
    required this.dopa,
    required this.human,
    required this.lines,
  });

  bool get isSd => rarity == Rarity.sd;
}