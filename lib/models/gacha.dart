import 'dart:math';

import '../data/cards.dart';
import '../data/theme.dart';
import 'card.dart';
import 'save_data.dart';

/// ガチャで出たもの
enum PullKind {
  sdCard, // SDカード入手
  dCard, // Dカード → かけら1個
  duplicate, // 所持済みSD → かけら3個
  part, // キャラメイクのパーツ解放
}

class PullResult {
  final PullKind kind;
  final GameCard? card;
  final String? partKey;
  final int partIndex;
  final int fragmentGain;
  final String note;

  PullResult({
    required this.kind,
    this.card,
    this.partKey,
    this.partIndex = 0,
    this.fragmentGain = 0,
    required this.note,
  });

  bool get isHit => kind == PullKind.sdCard;
  bool get isFragment =>
      kind == PullKind.dCard || kind == PullKind.duplicate;

  String get displayName {
    if (card != null) return card!.title;
    if (partKey != null) {
      return '${Parts.keyLabels[partKey]!}：${Parts.nameOf(partKey!, partIndex)}';
    }
    return '';
  }
}

/// 排出確率。表示もこの値から計算するので、ここを変えれば画面も追従する。
class GachaRates {
  static const double sd = 0.25;
  static const double d = 0.35;
  static const double part = 0.40;

  static int get sdPercent => (sd * 100).round();
  static int get dPercent => (d * 100).round();
  static int get partPercent => (part * 100).round();
}

class Gacha {
  static final _rand = Random();

  /// まだ解放していないパーツの一覧
  static List<(String, int)> lockedParts(SaveData save) {
    final list = <(String, int)>[];
    for (final key in Parts.keys) {
      for (var i = 0; i < Parts.count(key); i++) {
        if (!save.isPartUnlocked(key, i)) list.add((key, i));
      }
    }
    return list;
  }

  /// SDカードを1枚引く。所持済みならかけら3個になる。
  static PullResult pullSd(SaveData save) {
    final pool = cardsOf(Rarity.sd);
    final c = pool[_rand.nextInt(pool.length)];
    if (save.ownedSd.contains(c.id)) {
      save.fragments += 3;
      return PullResult(
        kind: PullKind.duplicate,
        card: c,
        fragmentGain: 3,
        note: 'すでに所持しているため かけら×3 になりました',
      );
    }
    save.ownedSd.add(c.id);
    return PullResult(
      kind: PullKind.sdCard,
      card: c,
      note: 'SD枠に3枚まで編成できます',
    );
  }

  /// Dカードは最初から編成できるので、必ずかけらになる。
  static PullResult pullD(SaveData save) {
    final pool = cardsOf(Rarity.d);
    final c = pool[_rand.nextInt(pool.length)];
    save.fragments += 1;
    return PullResult(
      kind: PullKind.dCard,
      card: c,
      fragmentGain: 1,
      note: 'Dカードは最初から編成できるため かけら×1 になりました',
    );
  }

  static PullResult? pullPart(SaveData save) {
    final locked = lockedParts(save);
    if (locked.isEmpty) return null;
    final (key, index) = locked[_rand.nextInt(locked.length)];
    save.parts.putIfAbsent(key, () => <int>{}).add(index);
    return PullResult(
      kind: PullKind.part,
      partKey: key,
      partIndex: index,
      note: 'キャラメイクで選べるようになりました',
    );
  }

  /// パーツを全部解放していると、パーツ枠はSDに振り替わる。
  static bool partsExhausted(SaveData save) => lockedParts(save).isEmpty;

  /// 実際にSD枠を引く確率（パーツ全解放後は上がる）
  static double sdSlotRate(SaveData save) =>
      partsExhausted(save) ? GachaRates.sd + GachaRates.part : GachaRates.sd;

  /// まだ持っていないSDカードを引き当てる確率。
  /// 集めるほど下がっていくので、そのまま表示する。
  static double newSdRate(SaveData save) {
    final all = cardsOf(Rarity.sd).length;
    final yet = all - save.ownedSd.length;
    if (yet <= 0) return 0;
    return sdSlotRate(save) * yet / all;
  }

  /// チケット1枚を消費して1回引く
  static PullResult roll(SaveData save) {
    save.tickets -= 1;
    final r = _rand.nextDouble();
    if (r < GachaRates.sd) return pullSd(save);
    if (r < GachaRates.sd + GachaRates.d) return pullD(save);
    return pullPart(save) ?? pullSd(save);
  }

  /// かけら10個をSDカード1枚と交換する。未所持のものを優先。
  static PullResult exchange(SaveData save) {
    save.fragments -= 10;
    final yet = cardsOf(Rarity.sd)
        .where((c) => !save.ownedSd.contains(c.id))
        .toList();
    if (yet.isEmpty) {
      final r = pullSd(save);
      return PullResult(
        kind: r.kind,
        card: r.card,
        fragmentGain: r.fragmentGain,
        note: '🧩10個と交換 ／ ${r.note}',
      );
    }
    final c = yet[_rand.nextInt(yet.length)];
    save.ownedSd.add(c.id);
    return PullResult(
      kind: PullKind.sdCard,
      card: c,
      note: '🧩10個と交換 ／ SD枠に3枚まで編成できます',
    );
  }
}