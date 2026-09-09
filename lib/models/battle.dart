import 'dart:math';

import '../models/dopaminer.dart';

/// 反ドパガキ勢力
class EnemyType {
  final String name;
  final String icon;
  const EnemyType(this.name, this.icon);
}

const List<EnemyType> kEnemies = [
  EnemyType('ＰＴＡ会長', '👩‍💼'),
  EnemyType('教育熱心な親', '👨‍👩‍👦'),
  EnemyType('スクリーンタイム制限', '⏰'),
  EnemyType('早寝早起き運動', '🌅'),
  EnemyType('デジタルデトックス講師', '🧘'),
  EnemyType('反ゲーム条例', '📜'),
  EnemyType('校則', '🏫'),
  EnemyType('塾のチューター', '👨‍🏫'),
  EnemyType('スマホ没収おじさん', '🙅'),
  EnemyType('規則正しい生活', '🥗'),
];

/// 戦闘中の味方1体
class Unit {
  final String name;
  final Look look;
  final int humanForFace;
  final int dopaForFace;
  final int atk;
  final double rate;
  final int maxHp;

  int hp;
  double gauge = 0;

  Unit({
    required this.name,
    required this.look,
    required this.humanForFace,
    required this.dopaForFace,
    required this.atk,
    required this.rate,
    required this.maxHp,
  }) : hp = maxHp;

  bool get alive => hp > 0;

  factory Unit.from(Dopaminer d) => Unit(
        name: d.name,
        look: d.look,
        humanForFace: d.human,
        dopaForFace: d.dopa,
        atk: d.atk,
        rate: d.rate,
        maxHp: d.maxHp,
      );
}

/// 現在の敵
class Enemy {
  final String name;
  final String icon;
  final int maxHp;
  final int atk;
  int hp;
  double gauge = 0;

  Enemy({
    required this.name,
    required this.icon,
    required this.maxHp,
    required this.atk,
  }) : hp = maxHp;

  factory Enemy.forFloor(int floor) {
    final t = kEnemies[(floor - 1) % kEnemies.length];
    final hp = (90 * pow(floor, 1.45)).round();
    return Enemy(
      name: floor > 10 ? '${t.name} Lv${(floor / 10).ceil()}' : t.name,
      icon: t.icon,
      maxHp: hp,
      atk: (8 * pow(floor, 1.2)).round(),
    );
  }
}

/// 1tickで起きたこと。演出に使う。
class BattleEvent {
  final List<int> attackers; // 攻撃した味方のindex
  final List<int> damaged; // 被弾した味方のindex
  final int toEnemy; // 敵に与えた合計ダメージ
  final int toAlly; // 味方が受けた1発分のダメージ
  final List<String> logs;
  final bool enemyDown;
  final bool wiped;

  BattleEvent({
    this.attackers = const [],
    this.damaged = const [],
    this.toEnemy = 0,
    this.toAlly = 0,
    this.logs = const [],
    this.enemyDown = false,
    this.wiped = false,
  });
}

/// 階層制のオート戦闘。人間性は一切関与しない。
class Battle {
  final List<Unit> party;
  int floor = 1;
  int kills = 0;
  late Enemy enemy;
  bool finished = false;

  final _rand = Random();

  Battle(List<Dopaminer> members)
      : party = members.map(Unit.from).toList() {
    enemy = Enemy.forFloor(floor);
  }

  /// チケットの獲得数（5階ごとに1枚）
  int get tickets => floor ~/ 5;

  String get rank {
    if (floor > 40) return 'SS';
    if (floor > 28) return 'S';
    if (floor > 18) return 'A';
    if (floor > 10) return 'B';
    return 'C';
  }

  /// 1tick進める
  BattleEvent tick() {
    if (finished) return BattleEvent();

    final logs = <String>[];
    final attackers = <int>[];
    var toEnemy = 0;

    // ---- 味方の攻撃（頭脳が高いほど頻度が上がる） ----
    for (var i = 0; i < party.length; i++) {
      final u = party[i];
      if (!u.alive) continue;
      u.gauge += u.rate;
      while (u.gauge >= 1) {
        u.gauge -= 1;
        enemy.hp -= u.atk;
        toEnemy += u.atk;
        if (!attackers.contains(i)) attackers.add(i);
        if (_rand.nextDouble() < 0.22) {
          logs.add('${u.name} の攻撃 ${u.atk}');
        }
      }
    }

    // ---- 撃破判定 ----
    if (enemy.hp <= 0) {
      enemy.hp = 0;
      kills++;
      logs.add('${enemy.name} を撃破！');
      floor++;
      // 少し回復して次の階へ
      for (final u in party) {
        if (u.alive) {
          u.hp = min(u.maxHp, u.hp + (u.maxHp * 0.15).round());
        }
      }
      enemy = Enemy.forFloor(floor);
      logs.add('${floor}F ${enemy.name} が現れた');
      return BattleEvent(
        attackers: attackers,
        toEnemy: toEnemy,
        logs: logs,
        enemyDown: true,
      );
    }

    // ---- 敵の攻撃 ----
    final damaged = <int>[];
    var toAlly = 0;
    enemy.gauge += 0.7;
    while (enemy.gauge >= 1) {
      enemy.gauge -= 1;
      final alive = <int>[];
      for (var i = 0; i < party.length; i++) {
        if (party[i].alive) alive.add(i);
      }
      if (alive.isEmpty) break;
      final target = alive[_rand.nextInt(alive.length)];
      party[target].hp -= enemy.atk;
      toAlly = enemy.atk;
      damaged.add(target);
      if (party[target].hp <= 0) {
        party[target].hp = 0;
        logs.add('${party[target].name} が脱落');
      }
    }

    // ---- 全滅判定 ----
    final wiped = !party.any((u) => u.alive);
    if (wiped) {
      finished = true;
      logs.add('${floor}F で全滅。');
    }

    return BattleEvent(
      attackers: attackers,
      damaged: damaged,
      toEnemy: toEnemy,
      toAlly: toAlly,
      logs: logs,
      wiped: wiped,
    );
  }
}