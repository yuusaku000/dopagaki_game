import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/theme.dart';
import '../models/battle.dart';
import '../models/save_data.dart';
import '../widgets/chara.dart';
import '../widgets/dopaminer_tile.dart';
import 'deck_list_screen.dart';

class DungeonScreen extends StatefulWidget {
  final SaveData save;
  const DungeonScreen({super.key, required this.save});

  @override
  State<DungeonScreen> createState() => _DungeonScreenState();
}

class _DungeonScreenState extends State<DungeonScreen> {
  final List<int> picked = [];
  SortKey sort = SortKey.dopa;

  Battle? battle;
  Timer? _timer;
  final List<String> _logs = [];

  /// 攻撃・被弾の演出用フラグ
  final Set<int> _attacking = {};
  final Set<int> _damaged = {};
  bool _enemyHit = false;
  bool _enemyAttacking = false;
  final List<_Damage> _pops = [];

  SaveData get save => widget.save;
  bool get inBattle => battle != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------- 開始 / 終了 ----------------
  void _start() {
    if (picked.isEmpty) {
      _toast('1人以上選んでください');
      return;
    }
    final members = picked.map((i) => save.dopaminers[i]).toList();
    setState(() {
      battle = Battle(members);
      _logs
        ..clear()
        ..add('1F ${battle!.enemy.name} が現れた');
    });
    _timer = Timer.periodic(const Duration(milliseconds: 420), (_) => _tick());
  }

  Future<void> _tick() async {
    final b = battle;
    if (b == null || b.finished) return;
    final e = b.tick();

    // 自己ベストとチケットの更新
    final reached = b.floor - (e.enemyDown ? 1 : 0);
    if (reached > save.bestFloor) {
      save.bestFloor = reached;
    }

    setState(() {
      _logs.addAll(e.logs);
      while (_logs.length > 60) {
        _logs.removeAt(0);
      }
      if (save.settings.anim) {
        _attacking
          ..clear()
          ..addAll(e.attackers);
        _damaged
          ..clear()
          ..addAll(e.damaged);
        _enemyHit = e.toEnemy > 0;
        _enemyAttacking = e.damaged.isNotEmpty;
        if (e.toEnemy > 0) {
          _pops.add(_Damage('-${e.toEnemy}', C.gold, true));
        }
        if (e.toAlly > 0) {
          _pops.add(_Damage('-${e.toAlly}', const Color(0xFFFF6B6B), false));
        }
      }
    });

    // 演出のリセット
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _attacking.clear();
        _damaged.clear();
        _enemyHit = false;
        _enemyAttacking = false;
      });
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _pops.clear());
    });

    if (e.wiped) {
      _timer?.cancel();
      save.tickets += b.tickets;
      await save.commit();
      if (mounted) setState(() {});
    }
  }

  void _retreat() {
    _timer?.cancel();
    setState(() {
      battle = null;
      _pops.clear();
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1300),
        behavior: SnackBarBehavior.floating,
      ));
  }

  // ---------------- 画面 ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    BackChip(onTap: () {
                      _timer?.cancel();
                      Navigator.of(context).pop();
                    }),
                    const SizedBox(width: 10),
                    const Text('ドパガキ道',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('最高 ${save.bestFloor}F',
                        style: const TextStyle(fontSize: 11, color: C.sub)),
                  ]),
                  const SizedBox(height: 12),
                  Expanded(
                    child: !inBattle
                        ? _prepare()
                        : (battle!.finished ? _result() : _arena()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- 編成 ----------------
  Widget _prepare() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ドパミナー最大3人で潜ります。\n'
          '頭脳＝攻撃頻度／ドパ欲＝攻撃力・耐久',
          style: TextStyle(fontSize: 11.5, color: C.sub, height: 1.85),
        ),
        const Text(
          '人間性は戦闘に一切関与しません。',
          style: TextStyle(fontSize: 11.5, color: C.human, height: 1.85),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Text('パーティ編成',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${picked.length} / 3',
              style: const TextStyle(fontSize: 11, color: C.sub)),
        ]),
        const SizedBox(height: 8),
        SortDropdown(
          value: sort,
          onChanged: (v) => setState(() => sort = v),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: save.dopaminers.isEmpty
              ? const Center(
                  child: Text('先にドパガキを育ててください。',
                      style: TextStyle(fontSize: 13, color: C.sub)))
              : ListView.separated(
                  itemCount: save.dopaminers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, k) {
                    final order = sortedIndices(save.dopaminers, sort);
                    final i = order[k];
                    return DopaminerTile(
                      d: save.dopaminers[i],
                      selected: picked.contains(i),
                      battleMode: true,
                      onTap: () => _toggle(i),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _start,
            style: ElevatedButton.styleFrom(
              backgroundColor: C.dopa,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('潜る',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _toggle(int i) {
    setState(() {
      if (picked.contains(i)) {
        picked.remove(i);
      } else if (picked.length < 3) {
        picked.add(i);
      } else {
        _toast('パーティは3人までです');
      }
    });
  }

  // ---------------- 戦闘中 ----------------
  Widget _arena() {
    final b = battle!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Text('${b.floor}F',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          const Text('反ドパガキ勢力',
              style: TextStyle(fontSize: 11, color: C.sub)),
        ]),
        const SizedBox(height: 8),
        _battleField(b),
        const SizedBox(height: 10),
        Expanded(child: _logView()),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _retreat,
            style: OutlinedButton.styleFrom(
              foregroundColor: C.txt,
              backgroundColor: C.panel2,
              side: const BorderSide(color: C.line),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('撤退する',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _battleField(Battle b) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0xFF33184A), Color(0xFF180F24)],
        ),
        border: Border.all(color: C.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左：味方3人を縦に
              SizedBox(
                width: 78,
                child: Column(
                  children: List.generate(
                    b.party.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: _unitCard(b.party[i], i),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              // 中央：敵
              Expanded(child: _enemyCard(b)),
              const SizedBox(width: 9),
              // 右：情報
              SizedBox(
                width: 74,
                child: Column(
                  children: [
                    const Text('敵ATK',
                        style: TextStyle(fontSize: 10, color: C.sub)),
                    Text('${b.enemy.atk}',
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF8080))),
                    const SizedBox(height: 10),
                    const Text('撃破',
                        style: TextStyle(fontSize: 10, color: C.sub)),
                    Text('${b.kills}',
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          // ダメージ表示
          ..._pops.map((p) => _DamagePop(key: ValueKey(p), damage: p)),
        ],
      ),
    );
  }

  Widget _unitCard(Unit u, int i) {
    final atk = _attacking.contains(i);
    final hit = _damaged.contains(i);
    final dx = atk ? 9.0 : (hit ? -5.0 : 0.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      transform: Matrix4.translationValues(dx, 0, 0),
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        border: Border.all(color: C.line),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Opacity(
        opacity: u.alive ? 1 : 0.28,
        child: Column(
          children: [
            CharaView(
                look: u.look,
                human: u.humanForFace,
                dopa: u.dopaForFace,
                size: CharaSize.unit),
            Text(u.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (u.hp / u.maxHp).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFF0D0A12),
                valueColor: const AlwaysStoppedAnimation(C.brain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _enemyCard(Battle b) {
    final dx = _enemyAttacking ? -9.0 : (_enemyHit ? 5.0 : 0.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      transform: Matrix4.translationValues(dx, 0, 0),
      child: Column(
        children: [
          Text(b.enemy.icon, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 5),
          Text(b.enemy.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, height: 1.3)),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: (b.enemy.hp / b.enemy.maxHp).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: const Color(0xFF0D0A12),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF44336)),
            ),
          ),
          const SizedBox(height: 4),
          Text('${max(0, b.enemy.hp)} / ${b.enemy.maxHp}',
              style: const TextStyle(fontSize: 10, color: C.sub)),
        ],
      ),
    );
  }

  Widget _logView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0A12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.builder(
        reverse: true,
        itemCount: _logs.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            _logs[_logs.length - 1 - i],
            style: const TextStyle(fontSize: 11.5, color: C.sub, height: 1.6),
          ),
        ),
      ),
    );
  }

  // ---------------- リザルト ----------------
  Widget _result() {
    final b = battle!;
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: C.panel,
            border: Border.all(color: C.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Text('到達階層',
                  style: TextStyle(fontSize: 13, color: C.sub)),
              Text('${b.floor}F',
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.w900, color: C.gold)),
              const SizedBox(height: 6),
              Text(
                '撃破数 ${b.kills} 体\n'
                'ランク ${b.rank}\n'
                '獲得 🎫 ${b.tickets}枚（自己ベスト ${save.bestFloor}F）',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, color: C.sub, height: 1.9),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.dopa,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ホームへ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _retreat,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.txt,
                    backgroundColor: C.panel2,
                    side: const BorderSide(color: C.line),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('もう一度潜る',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// ダメージ数値
// =====================================================================
class _Damage {
  final String text;
  final Color color;
  final bool toEnemy;
  _Damage(this.text, this.color, this.toEnemy);
}

class _DamagePop extends StatefulWidget {
  final _Damage damage;
  const _DamagePop({super.key, required this.damage});

  @override
  State<_DamagePop> createState() => _DamagePopState();
}

class _DamagePopState extends State<_DamagePop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Positioned(
          left: widget.damage.toEnemy ? null : 20,
          right: widget.damage.toEnemy ? 96 : null,
          top: 40 - t * 30,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Text(
              widget.damage.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: widget.damage.color,
                shadows: const [
                  Shadow(
                      color: Colors.black, blurRadius: 6, offset: Offset(0, 2))
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}