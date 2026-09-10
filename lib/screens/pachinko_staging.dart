import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/theme.dart';
import '../models/dopaminer.dart';
import '../models/gacha.dart';
import '../widgets/chara.dart';
import '../widgets/staging_effects.dart';

// =====================================================================
// 期待度（熱さ）
// =====================================================================
enum Heat { white, blue, green, red, rainbow }

extension HeatInfo on Heat {
  String get label => switch (this) {
        Heat.white => 'ノーマル',
        Heat.blue => 'チャンス',
        Heat.green => 'ドパチャンス',
        Heat.red => '激アツ',
        Heat.rainbow => '超激アツ',
      };

  String get notice => switch (this) {
        Heat.white => 'ドパ予告',
        Heat.blue => 'スマホ通知予告',
        Heat.green => '深夜アラート',
        Heat.red => '課金圧 発生',
        Heat.rainbow => 'ドーパミン 大放出',
      };

  Color get color => switch (this) {
        Heat.white => const Color(0xFFE8E4F0),
        Heat.blue => const Color(0xFF4FA3FF),
        Heat.green => const Color(0xFF4CCF7D),
        Heat.red => const Color(0xFFFF3D3D),
        Heat.rainbow => const Color(0xFFFFD54F),
      };

  bool get isRainbow => this == Heat.rainbow;
}

/// 背景。演出が進むほど夜が深くなる。
enum Backdrop { room, night, city, space }

// =====================================================================
// 演出の設計図。引く前に全部決めておく。
// =====================================================================
class StagingPlan {
  final bool win;
  final Heat heat;
  final int pseudoCount;
  final bool reach;
  final bool cutin;
  final bool revive;
  final bool fakeRevive; // ハズレなのに復活煽りだけ入る
  final bool crowd;
  final bool lineNotice;
  final bool drop;
  final bool button;
  final bool countdown;
  final bool allSpin;
  final int spinUp; // テンパイ後の「きゅいんきゅいん」の回数
  final bool blackout; // 画面がプツッと消える
  final bool shorts; // ショート動画スワイプ
  final bool tapRush; // 連打演出
  final int symbol; // 揃う図柄（当たり時）／テンパイ図柄（ハズレ時）
  final bool sudden; // 一発告知：予告もリーチもなく突然揃う
  final bool slip; // 滑り：一度外して1コマ動いて揃う
  final bool rightFirst; // 停止順を逆にする

  StagingPlan({
    required this.win,
    required this.heat,
    required this.pseudoCount,
    required this.reach,
    required this.cutin,
    required this.revive,
    required this.fakeRevive,
    required this.crowd,
    required this.lineNotice,
    required this.drop,
    required this.button,
    required this.countdown,
    required this.allSpin,
    required this.spinUp,
    required this.blackout,
    required this.shorts,
    required this.tapRush,
    required this.symbol,
    required this.sudden,
    required this.slip,
    required this.rightFirst,
  });

  /// 図柄の並び。6が💊、7が「7」でプレミア扱い。
  static const int pillSymbol = 6;
  static const int sevenSymbol = 7;

  factory StagingPlan.make(bool win, Random r) {
    T pick<T>(List<T> pool) => pool[r.nextInt(pool.length)];
    bool chance(double p) => r.nextDouble() < p;

    // 揃う図柄（当たり時）／テンパイ図柄（ハズレ時）。7が最も出にくい。
    final symbol = pick([
      0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5,
      pillSymbol, pillSymbol,
      sevenSymbol,
    ]);
    final premium = symbol >= pillSymbol;

    // --- 熱さ ---
    var heat = win
        ? pick([
            Heat.blue, Heat.blue, Heat.blue,
            Heat.green, Heat.green, Heat.green, Heat.green,
            Heat.red,
            Heat.rainbow,
          ])
        : pick([
            ...List.filled(14, Heat.white),
            ...List.filled(8, Heat.blue),
            ...List.filled(4, Heat.green),
            Heat.red,
            Heat.rainbow,
          ]);
    if (win && premium && heat.index < 3) {
      heat = Heat.values[min(4, heat.index + 1)];
    }
    final hot = heat.index >= 3;

    // --- 当たり方（排他。合計で当たりの100%を割り振る） ---
    // 全回転5% / 一発告知7% / 滑り20% / ハズレ落ち復活5% / 残りは通常
    String finish;
    if (win) {
      final f = r.nextDouble();
      if (f < 0.05) {
        finish = 'allSpin';
      } else if (f < 0.12) {
        finish = 'sudden';
      } else if (f < 0.32) {
        finish = 'slip';
      } else if (f < 0.37) {
        finish = 'revive';
      } else {
        finish = 'normal';
      }
    } else {
      finish = 'lose';
    }

    final allSpin = finish == 'allSpin';
    final sudden = finish == 'sudden';
    final slip = finish == 'slip';
    final revive = finish == 'revive';

    // 予告類は緑(index>=1)から出るように敷居を下げ、当たり青でも寂しくないように。
    // sudden / allSpin のときは道中を省く。
    final skipRoute = sudden || allSpin;
    double heatBias(double base) => base + heat.index * 0.12;

    return StagingPlan(
      win: win,
      heat: heat,
      symbol: symbol,
      allSpin: allSpin,
      sudden: sudden,
      slip: slip,
      revive: revive,
      fakeRevive: !win && chance(0.05),
      rightFirst: chance(0.35),
      reach: win || heat.index >= 1 || chance(0.30),
      pseudoCount: skipRoute
          ? 0
          : (win ? pick([0, 1, 1, 2, 2, 3]) : pick([0, 0, 0, 0, 1, 1, 2])),
      // 予告：緑以上でよく出る。当たりは底上げ。
      lineNotice: !skipRoute && chance(heatBias(win ? 0.35 : 0.30)),
      crowd: !skipRoute && heat.index >= 1 && chance(heatBias(win ? 0.4 : 0.25)),
      drop: !skipRoute && heat.index >= 1 && chance(heatBias(win ? 0.35 : 0.2)),
      cutin: !skipRoute && heat.index >= 1 && chance(heatBias(win ? 0.55 : 0.3)),
      spinUp: skipRoute
          ? 0
          : (win ? pick([1, 1, 2, 2, 3]) : pick([0, 0, 1, 1, 2])),
      countdown: !skipRoute && hot && chance(0.5),
      blackout: !skipRoute && heat.index >= 2 && chance(win ? 0.5 : 0.3),
      button: !skipRoute && (hot || chance(win ? 0.4 : 0.15)),
      // 参加型
      shorts: !skipRoute && heat.index >= 2 && chance(win ? 0.28 : 0.16),
      tapRush: !skipRoute && heat.index >= 3 && chance(0.45),
    );
  }
}

// =====================================================================
// 演出画面
// =====================================================================
class PachinkoStaging extends StatefulWidget {
  final PullResult result;
  final int fragments;

  const PachinkoStaging({
    super.key,
    required this.result,
    required this.fragments,
  });

  @override
  State<PachinkoStaging> createState() => _PachinkoStagingState();
}

enum _Phase { spin, reach, pseudo, judge, lose, revive, result }

class _PachinkoStagingState extends State<PachinkoStaging>
    with TickerProviderStateMixin {
  final _rand = Random();
  late final StagingPlan plan;

  _Phase phase = _Phase.spin;
  Backdrop backdrop = Backdrop.room;
  bool _skipped = false;
  bool _done = false;

  final List<int> reels = [0, 0, 0];
  final List<bool> spinning = [true, true, true];
  Timer? _spinTimer;

  Heat _current = Heat.white;
  Heat? _notice;
  int _step = 0;

  String? _bigText;
  Color _bigColor = Colors.white;

  bool _cutinShown = false;
  String _cutinLine = '';
  bool _crowd = false;
  bool _drop = false;
  bool _burst = false;
  String? _line;
  int? _countdown;

  bool _showButton = false;
  Completer<void>? _buttonDone;
  Completer<void>? _interactDone;

  bool _blackout = false;
  bool _shorts = false;
  bool _tapRush = false;
  bool _dopaBurst = false;
  bool _shakeScreen = false;
  double _shakePower = 6;
  int _shakeToken = 0;
  int _spinUpCount = 0; // 何回きゅいんしたか（画面表示用）
  bool _jackpot = false; // 大当たりファンファーレ
  bool _focus = false; // 集中線
  bool _afterglow = false; // ハズレの余韻
  bool _canClose = false; // 結果を見せきるまで閉じさせない
  bool _confetti = false; // 当たりの余韻

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  bool get _bail => !mounted || _skipped;

  static const _lines = [
    'まだ寝てないの？',
    '通知、来てる',
    'あと1回だけ…',
    '充電、切れそう',
    'もう朝じゃん',
  ];

  @override
  void initState() {
    super.initState();
    plan = StagingPlan.make(widget.result.isHit, _rand);
    _startSpin();
    _run();
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _pulse.dispose();
    _shake.dispose();
    super.dispose();
  }

  // ---------------- リール ----------------
  void _startSpin() {
    _spinTimer?.cancel();
    _spinTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < 3; i++) {
          if (spinning[i]) reels[i] = (reels[i] + 1) % 8;
        }
      });
    });
  }

  Future<void> _stopReel(int index, int value, {bool slow = false}) async {
    if (slow) {
      // 最後の1つは1コマずつ、だんだん重くなって止まる
      for (var step = 5; step > 0; step--) {
        if (_bail) break;
        setState(() => reels[index] = (value - step + 8) % 8);
        _shake.forward(from: 0);
        await Future.delayed(Duration(milliseconds: 130 + (5 - step) * 95));
      }
    }
    if (!mounted) return;
    setState(() {
      spinning[index] = false;
      reels[index] = value;
    });
  }

  Future<void> _wait(int ms) async {
    if (_skipped) return;
    await Future.delayed(Duration(milliseconds: ms));
  }

  Future<void> _show(String text, Color color, int ms) async {
    if (_bail) return;
    setState(() {
      _bigText = text;
      _bigColor = color;
    });
    await _wait(ms);
    if (!mounted) return;
    setState(() => _bigText = null);
  }

  // ---------------- 進行 ----------------
  Future<void> _run() async {
    try {
      // ---- 一発告知：前触れなく揃う ----
      if (plan.sudden) {
        await _wait(900);
        if (_bail) return;
        for (var i = 0; i < 3; i++) {
          await _stopReel(i, plan.symbol);
          await _wait(150);
        }
        await _wait(400);
        if (!mounted) return;
        await _jackpotFanfare();
        await _finish();
        return;
      }

      // ---- 保留変化 ----
      await _wait(600);
      if (_bail) return;
      if (plan.heat.index >= 2) {
        setState(() => _current = Heat.values[max(1, plan.heat.index - 1)]);
        await _show('保留変化', _current.color, 800);
        if (_bail) return;
      }

      // ---- 回転開始 ----
      setState(() => phase = _Phase.spin);
      await _wait(700);
      if (_bail) return;

      // ---- セリフ予告 ----
      if (plan.lineNotice) {
        setState(() => _line = _lines[_rand.nextInt(_lines.length)]);
        await _wait(1100);
        if (_bail) return;
        setState(() => _line = null);
        await _wait(250);
      }

      // ---- 役物落下 ----
      if (plan.drop) {
        setState(() => _drop = true);
        await _wait(600);
        _quake(200, 9); // 着地の衝撃
        await _wait(500);
        if (_bail) return;
        setState(() => _drop = false);
        await _wait(200);
      }

      // ---- ステップアップ予告 ----
      for (var i = 0; i <= plan.heat.index; i++) {
        if (_bail) return;
        final h = Heat.values[i];
        setState(() {
          _current = h;
          _notice = h;
          _step = i + 1;
          backdrop = Backdrop.values[min(i, Backdrop.values.length - 1)];
        });
        await _wait(h.isRainbow ? 1200 : 800);
        if (_bail) return;
        setState(() => _notice = null);
        await _wait(180);
      }

      // ---- 群予告 ----
      if (plan.crowd) {
        setState(() => _crowd = true);
        await _show('ドパガキの群れ', _current.color, 600);
        await _wait(1300);
        if (_bail) return;
        setState(() => _crowd = false);
        await _wait(200);
      }

      // ---- 擬似連 ----
      for (var i = 0; i < plan.pseudoCount; i++) {
        if (_bail) return;
        setState(() => phase = _Phase.pseudo);
        // タメ：一拍おいてから回し直す
        await _wait(650);
        if (_bail) return;
        setState(() {
          for (var k = 0; k < 3; k++) {
            spinning[k] = true;
          }
        });
        await _wait(750);
      }

      // ---- 全回転（確定演出） ----
      if (plan.allSpin) {
        _quake(220, 8);
        await _show('全 回 転', const Color(0xFFFFD54F), 1200);
        if (_bail) return;
        await _wait(900);
        for (var i = 0; i < 3; i++) {
          await _stopReel(i, 7);
          await _wait(220);
        }
        await _wait(600);
        if (!mounted) return;
        await _jackpotFanfare();
        await _finish();
        return;
      }

      // ---- 左右のリールを止める ----
      final target = plan.symbol;
      final first = plan.rightFirst ? 2 : 0;
      final second = plan.rightFirst ? 0 : 2;

      await _stopReel(first, target);
      await _wait(420);
      if (_bail) return;

      if (!plan.reach) {
        // リーチにすらならない即ハズレ
        await _stopReel(1, (target + 2 + _rand.nextInt(3)) % 8);
        await _wait(300);
        await _stopReel(second, (target + 5) % 8);
        await _wait(700);
        if (!mounted) return;
        await _loseAfterglow();
        await _finish();
        return;
      }

      await _stopReel(second, target);
      _quake(200, 7);
      if (_bail) return;

      // プレミア図柄でのテンパイは、その時点で告知する
      if (target >= StagingPlan.sevenSymbol) {
        _quake(240, 11);
        await _show('7 テンパイ', const Color(0xFFFFD54F), 900);
      } else if (target == StagingPlan.pillSymbol) {
        _quake(240, 9);
        await _show('💊 テンパイ', const Color(0xFFC084FC), 900);
      }
      if (_bail) return;

      // ---- リーチ ----
      setState(() => phase = _Phase.reach);
      _quake(200, 8);
      await _show('リーチ！', _current.color, 900);
      if (_bail) return;

      // ---- ショート動画スワイプ ----
      if (plan.shorts) {
        await _interactive((v) => _shorts = v);
        if (!mounted) return;
        setState(() => backdrop = Backdrop.space);
        if (_bail) return;
      }

      // ---- きゅいん、きゅいん ----
      if (plan.spinUp > 0) {
        await _spinUp(plan.spinUp, target);
        if (_bail) return;
        if (plan.spinUp >= 3) {
          _quake(240, 11);
          await _show('激 熱', const Color(0xFFFF3D3D), 900);
          if (_bail) return;
        }
        await _wait(400); // きゅいんの後のタメ
      }

      // ---- カウントダウン ----
      if (plan.countdown) {
        for (var n = 3; n >= 0; n--) {
          if (_bail) return;
          setState(() => _countdown = n);
          await _wait(520);
        }
        if (!mounted) return;
        setState(() => _countdown = null);
      }

      // ---- カットイン ----
      if (plan.cutin) {
        setState(() {
          _cutinShown = true;
          _cutinLine = _pickLine();
        });
        await _wait(1200);
        if (_bail) return;
        setState(() => _cutinLine = plan.heat.index >= 3 ? '当たれ……！' : '当たれ…');
        _quake(260, 12); // 締めの一撃
        await _wait(1100);
        if (_bail) return;
        setState(() => _cutinShown = false);
        await _wait(250);
      }

      if (plan.heat.isRainbow) {
        _quake(240, 12);
        await _show('超激アツ', const Color(0xFFFFD54F), 1000);
        if (_bail) return;
      }

      // ---- 連打演出 ----
      if (plan.tapRush) {
        await _interactive((v) => _tapRush = v);
        if (_bail) return;
      }

      // ---- ボタン演出 ----
      if (plan.button) {
        _buttonDone = Completer<void>();
        setState(() => _showButton = true);
        await Future.any([
          _buttonDone!.future,
          Future.delayed(const Duration(milliseconds: 3200)),
        ]);
        if (!mounted) return;
        setState(() => _showButton = false);
        _buttonDone = null;
        await _wait(400);
        if (_bail) return;
      }

      // ---- ブラックアウト：一度画面を消してから結果へ ----
      if (plan.blackout) {
        setState(() => _blackout = true);
        // タップに関係なく自動で進む。短めに。
        await Future.delayed(const Duration(milliseconds: 850));
        if (!mounted) return;
        setState(() {
          _blackout = false;
          backdrop = Backdrop.space;
        });
        await Future.delayed(const Duration(milliseconds: 250));
      }

      // ---- 中リールの停止 ----
      setState(() => phase = _Phase.judge);
      // 中リールが下りてくる前のタメ
      await _wait(500);
      if (_bail) return;
      if (plan.slip) {
        // 外れ目でいったん止まる（当たりの1つ手前で止めると一番ひりつく）
        final near = (target - 1 + 8) % 8;
        await _stopReel(1, near, slow: true);
        // タメ：止まったまま息を呑む間
        await _wait(1100);
        if (_bail) return;
        // カクッと1コマ動いて揃う
        _quake(220, 13);
        setState(() => reels[1] = target);
        await _wait(900);
      } else {
        // 復活を使うときは、いったん外れ目で止める
        final matched = plan.win && !plan.revive;
        // 外すときは当たり図柄の1つ後ろ（＝あと一歩）で止める
        final middle = matched ? target : (target + 1) % 8;
        await _stopReel(1, middle, slow: true);
        // タメ：結果を見せる間
        await _wait(1000);
      }
      if (_bail) return;

      // ---- ハズレなのに復活煽り（空振り） ----
      if (plan.fakeRevive) {
        setState(() => phase = _Phase.lose);
        await _show('…ハズレ', const Color(0xFF6B5A8A), 1000);
        if (_bail) return;
        setState(() => phase = _Phase.revive);
        _quake(240, 11);
        await _show('復活…！？', const Color(0xFFFFD54F), 1100);
        if (_bail) return;
        // タメてから…戻らない
        setState(() => _shakeToken++);
        await _wait(900);
        if (_bail) return;
        await _show('ならず', const Color(0xFF6B5A8A), 900);
        if (_bail) return;
      }

      // ---- 復活（当たり） ----
      if (plan.revive) {
        setState(() => phase = _Phase.lose);
        await _show('…ハズレ', const Color(0xFF6B5A8A), 1200);
        if (_bail) return;
        setState(() => phase = _Phase.revive);
        await _wait(600);
        _quake(260, 12);
        await _show('復 活', const Color(0xFFFFD54F), 1200);
        if (_bail) return;
        setState(() => reels[1] = plan.symbol);
        await _wait(700);
      }

      if (plan.win && mounted) {
        await _jackpotFanfare();
      } else if (mounted) {
        await _loseAfterglow();
      }
      await _finish();
    } finally {
      // スキップされた場合でも、当たりならファンファーレだけは見せる
      if (mounted && !_done) {
        if (plan.win) await _jackpotFanfare();
        await _finish();
      }
    }
  }

  /// 短く画面を揺らす。awaitしないので、演出と並行して走る。
  void _quake(int ms, [double power = 7]) {
    if (!mounted) return;
    final token = ++_shakeToken;
    setState(() {
      _shakeScreen = true;
      _shakePower = power;
    });
    Future.delayed(Duration(milliseconds: ms), () {
      if (mounted && token == _shakeToken) {
        setState(() => _shakeScreen = false);
      }
    });
  }

  /// 参加型の演出。押し切るまで先へ進まない。
  Future<void> _interactive(void Function(bool) toggle) async {
    final done = Completer<void>();
    _interactDone = done;
    setState(() => toggle(true));
    await done.future;
    if (!mounted) return;
    setState(() => toggle(false));
    _interactDone = null;
    await _wait(280);
  }

  /// 図柄が揃った瞬間の大当たり演出。結果表示の前に一度これを挟む。
  Future<void> _jackpotFanfare() async {
    if (!mounted) return;
    // 集中線 → 揺れ → 虹色の乱舞
    _shakeToken++;
    setState(() {
      _focus = true;
      _shakeScreen = true;
      _shakePower = 8;
      _dopaBurst = true;
    });
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() => _jackpot = true);
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    setState(() {
      _focus = false;
      _shakeScreen = false;
      _jackpot = false;
    });
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// ハズレの余韻。すぐ結果に飛ばさず、静かになる時間を置く。
  Future<void> _loseAfterglow() async {
    if (!mounted) return;
    setState(() => _afterglow = true);
    await Future.delayed(const Duration(milliseconds: 2300));
    if (!mounted) return;
    setState(() => _afterglow = false);
  }

  Future<void> _finish() async {
    if (!mounted || _done) return;
    _spinTimer?.cancel();
    setState(() {
      phase = _Phase.result;
      _done = true;
      _crowd = false;
      _drop = false;
      _showButton = false;
      _countdown = null;
      _cutinShown = false;
      _line = null;
      _bigText = null;
      _blackout = false;
      _shorts = false;
      _tapRush = false;
      _shakeScreen = false;
      _spinUpCount = 0;
      _jackpot = false;
      _focus = false;
      _afterglow = false;
      _dopaBurst = widget.result.isHit;
      _confetti = widget.result.isHit;
      for (var i = 0; i < 3; i++) {
        spinning[i] = false;
      }
      if (widget.result.isHit) _burst = true;
    });
    // 結果をしばらく見せてから、進めるようにする
    await Future.delayed(Duration(
        milliseconds: widget.result.isHit ? 1800 : 1100));
    if (mounted) setState(() => _canClose = true);
  }

  /// テンパイ後の「きゅいん、きゅいん」。
  /// 中リールが図柄1つ分だけ戻って、また回り出すのを繰り返す。
  Future<void> _spinUp(int times, int target) async {
    for (var n = 1; n <= times; n++) {
      if (_bail) return;
      _shakeToken++;
      setState(() {
        _spinUpCount = n;
        _shakeScreen = true;
        _shakePower = 5.0 + n * 2;
        _dopaBurst = true;
        // 惜しい位置でいったん止まって…
        spinning[1] = false;
        reels[1] = (target - 1 + 8) % 8;
      });
      await _wait(260);
      if (_bail) return;
      // …また回り出す
      setState(() => spinning[1] = true);
      await _wait(120 + n * 40);
      if (!mounted) return;
      setState(() => _dopaBurst = false);
      await _wait(360 + n * 90);
      if (_bail) return;
      setState(() {
        spinning[1] = false;
        reels[1] = (target - 1 + 8) % 8;
      });
      await _wait(180);
    }
    if (!mounted) return;
    setState(() {
      _shakeScreen = false;
      _spinUpCount = 0;
    });
  }

  String _pickLine() {
    final pool = plan.heat.index >= 3
        ? ['ここで決めろ', 'まだいける', '来い……']
        : ['当たれ…', 'たのむ…', 'あと1回だけ'];
    return pool[_rand.nextInt(pool.length)];
  }

  void _tap() {
    // 結果が出ていれば閉じる。それ以外の画面タップでは何もしない。
    if (_done && _canClose) Navigator.of(context).pop();
    if (_showButton && _buttonDone != null && !_buttonDone!.isCompleted) {
      _buttonDone!.complete();
    }
  }

  /// スキップは専用ボタンからのみ
  void _skip() {
    if (_done || _tapRush || _shorts) return;
    setState(() => _skipped = true);
  }

  // ---------------- 描画 ----------------
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: Material(
        // 他の画面と同じく、横幅は460までに収める
        color: C.bg,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ScreenShake(
          active: _shakeScreen,
          intensity: _shakePower + _spinUpCount * 1.0,
          child: Stack(
          children: [
            Positioned.fill(child: _backdrop()),
            if (_dopaBurst)
              Positioned.fill(
                  child: DopamineBurst(strong: widget.result.isHit)),
            SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_current.isRainbow && !_done) const _RainbowSweep(),
                  Column(
                    children: [
                      _topBar(),
                      const Spacer(),
                      if (_done) _resultBlock() else _stagingBlock(),
                      const Spacer(),
                      _bottom(),
                    ],
                  ),
                  if (_crowd) const Positioned.fill(child: CrowdOverlay()),
                  if (_drop) DropObject(color: _current.color),
                  if (_line != null)
                    LineNotice(text: _line!, color: _current.color),
                  if (_countdown != null)
                    CountdownText(value: _countdown!, color: _current.color),
                  if (_cutinShown) _cutin(),
                  if (_bigText != null) _bigBanner(),
                  if (_showButton)
                    Positioned.fill(
                      child: PushButton(
                        color: _current.color,
                        onPush: () {
                          if (_buttonDone != null &&
                              !_buttonDone!.isCompleted) {
                            _buttonDone!.complete();
                          }
                        },
                      ),
                    ),
                  if (_burst) const Positioned.fill(child: BurstOverlay()),
                  if (_spinUpCount > 0) _spinUpBanner(),
                ],
              ),
            ),
            if (_afterglow) const Positioned.fill(child: LoseAfterglow()),
            if (_confetti) const Positioned.fill(child: ConfettiRain()),
            if (_focus)
              Positioned.fill(child: FocusLines(color: _current.color)),
            if (_jackpot)
              Positioned.fill(
                child: JackpotOverlay(
                  text: _jackpotTitle,
                  subText: widget.result.card?.title,
                ),
              ),
            if (_tapRush)
              Positioned.fill(
                child: TapRush(
                  required: 20,
                  maxStage: _current.index,
                  onFilled: _completeInteract,
                ),
              ),
            if (_shorts)
              Positioned.fill(
                child: ShortsSwipe(
                  required: 5,
                  maxStage: _current.index,
                  onFilled: _completeInteract,
                ),
              ),
            if (_blackout) const Positioned.fill(child: BlackoutOverlay()),
          ],
        ),
        ),
          ),
        ),
      ),
    );
  }

  /// 揃った図柄で当たりの呼び名を変える
  String get _jackpotTitle {
    if (plan.symbol >= StagingPlan.sevenSymbol) return '7 揃い';
    if (plan.symbol == StagingPlan.pillSymbol) return '💊 揃い';
    return '大当たり';
  }

  void _completeInteract() {
    if (_interactDone != null && !_interactDone!.isCompleted) {
      _interactDone!.complete();
    }
  }

  /// きゅいん中の表示
  Widget _spinUpBanner() {
    return Align(
      alignment: const Alignment(0, 0.42),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_spinUpCount),
        tween: Tween(begin: 1.6, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Text(
          '× $_spinUpCount',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: _spinUpCount >= 3 ? const Color(0xFFFF3D3D) : C.gold,
            shadows: const [Shadow(color: Colors.black, blurRadius: 12)],
          ),
        ),
      ),
    );
  }

  Widget _backdrop() {
    final colors = switch (backdrop) {
      Backdrop.room => [const Color(0xFF2A1E3A), Colors.black],
      Backdrop.night => [const Color(0xFF1A2A4A), Colors.black],
      Backdrop.city => [const Color(0xFF3A1E4A), Colors.black],
      Backdrop.space => [const Color(0xFF12061F), Colors.black],
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.15,
          colors: [
            Color.lerp(colors[0], _current.color,
                _done ? 0.05 : _current.index * 0.06)!,
            colors[1],
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _current.color.withValues(alpha: 0.18),
              border: Border.all(color: _current.color),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(_current.label,
                style: TextStyle(
                    fontSize: 12,
                    color: _current.color,
                    fontWeight: FontWeight.w900)),
          ),
          if (_step > 0 && !_done) ...[
            const SizedBox(width: 8),
            Text('STEP $_step',
                style: TextStyle(
                    fontSize: 11,
                    color: _current.color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold)),
          ],
          const Spacer(),
          Row(
            children: List.generate(4, (i) {
              final active = i == 0;
              return Container(
                width: 13,
                height: 13,
                margin: const EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                  color: active
                      ? _current.color
                      : Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: active && _current != Heat.white
                      ? [
                          BoxShadow(
                              color: _current.color.withValues(alpha: 0.7),
                              blurRadius: 10)
                        ]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(width: 10),
          if (!_done && !_showButton && !_tapRush && !_shorts)
            GestureDetector(
              onTap: _skip,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('スキップ ▶▶',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stagingBlock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_notice != null) ...[
          _noticeBanner(_notice!),
          const SizedBox(height: 18),
        ],
        _reelRow(),
        const SizedBox(height: 20),
        AnimatedOpacity(
          opacity: phase == _Phase.reach || phase == _Phase.judge ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: Text('R E A C H',
              style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w900,
                  color: _current.color)),
        ),
      ],
    );
  }

  Widget _noticeBanner(Heat h) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Transform.scale(
        scale: 1 + _pulse.value * 0.05,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: h.color.withValues(alpha: 0.16),
            border: Border.all(color: h.color, width: 2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: h.color.withValues(alpha: 0.5), blurRadius: 20)
            ],
          ),
          child: h.isRainbow
              ? RainbowText(h.notice, size: 17)
              : Text(h.notice,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: h.color)),
        ),
      ),
    );
  }

  static const _symbols = ['1', '2', '3', '4', '5', '6', '💊', '7'];

  Widget _reelRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final shaking = i == 1 && phase == _Phase.judge;
        return AnimatedBuilder(
          animation: _shake,
          builder: (_, child) {
            final dy = shaking ? sin(_shake.value * pi * 3) * 4 : 0.0;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: Container(
            width: 74,
            height: 92,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF120E18),
              border: Border.all(
                color: spinning[i]
                    ? const Color(0xFF3A3050)
                    : _current.color.withValues(alpha: 0.8),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: !spinning[i] && _current != Heat.white
                  ? [
                      BoxShadow(
                          color: _current.color.withValues(alpha: 0.35),
                          blurRadius: 14)
                    ]
                  : null,
            ),
            child: Opacity(
              opacity: spinning[i] ? 0.55 : 1,
              child: Text(
                _symbols[reels[i]],
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: reels[i] == StagingPlan.sevenSymbol
                      ? const Color(0xFFFFD54F)
                      : reels[i] == StagingPlan.pillSymbol
                          ? const Color(0xFFC084FC)
                          : Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _cutin() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: -1, end: 0),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Transform.translate(
                    offset: Offset(v * 200, 0), child: child),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: CharaView(
                    look: Look(hair: 2, hairColor: 4, cloth: 1),
                    human: 18,
                    dopa: 600,
                    size: CharaSize.hero,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _current.isRainbow
                      ? RainbowText(_cutinLine, size: 30)
                      : Text(
                          _cutinLine,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: _current.color,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 12)
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigBanner() {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_bigText),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (_, v, child) =>
            Transform.scale(scale: 0.6 + v * 0.4, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            border: Border.all(color: _bigColor, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: _bigColor.withValues(alpha: 0.45), blurRadius: 26)
            ],
          ),
          child: Text(
            _bigText ?? '',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: _bigColor),
          ),
        ),
      ),
    );
  }

  // ---------------- 結果 ----------------
  Widget _resultBlock() {
    final r = widget.result;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (r.isHit) ...[
            const RainbowText('SD 確定', size: 34),
            const SizedBox(height: 16),
            const Text('🃏', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            RainbowText(r.displayName, size: 24),
            const SizedBox(height: 12),
            Text(
              '頭脳 ${_s(r.card!.brain)}　ドパ欲 +${r.card!.dopa}　人間性 ${_s(r.card!.human)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFC3A8DD)),
            ),
            // かぶりでも大当たり。報酬がかけらになるだけ。
            if (r.isDuplicate) ...[
              const SizedBox(height: 14),
              const Text('所持済み → 🧩 ×3',
                  style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFFFCF8A),
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('かけら ${widget.fragments} / 10',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFFFCF8A))),
            ] else ...[
              const SizedBox(height: 12),
              const Text('NEW！',
                  style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFFF9EC2),
                      fontWeight: FontWeight.w900)),
            ],
          ] else if (r.kind == PullKind.part) ...[
            const Text('パーツ解放',
                style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFFA99AC0),
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            _partPreview(),
            const SizedBox(height: 8),
            Text(r.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFDCD2EA))),
          ] else ...[
            const Text(
              'D カード',
              style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF9DC0FF),
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            const Text('🃏', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            Text(r.displayName,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9DC0FF))),
            const SizedBox(height: 16),
            const Text(
              'Dカードは最初から編成可能',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFFFCF8A),
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('🧩 ×${r.fragmentGain}', style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text('かけらに交換　${widget.fragments} / 10',
                style: const TextStyle(fontSize: 12, color: Color(0xFFFFCF8A))),
          ],
        ],
      ),
    );
  }

  Widget _partPreview() {
    final r = widget.result;
    final key = r.partKey!;
    if (key == 'hairColor' || key == 'skin' || key == 'cloth') {
      final color = switch (key) {
        'hairColor' => Parts.hairColors[r.partIndex],
        'skin' => Parts.skins[r.partIndex],
        _ => Parts.clothes[r.partIndex],
      };
      return Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white30, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }
    final look = Look();
    if (key == 'hair') look.hair = r.partIndex;
    if (key == 'face') look.face = r.partIndex;
    return CharaView(look: look, size: CharaSize.preview);
  }

  Widget _bottom() => Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Text(
          _done && _canClose ? 'タップして進む' : '',
          style: const TextStyle(fontSize: 12, color: Color(0xFFC3A8DD)),
        ),
      );

  String _s(int v) => v > 0 ? '+$v' : '$v';
}

// =====================================================================
// 虹演出：斜めに流れる光
// =====================================================================
class _RainbowSweep extends StatefulWidget {
  const _RainbowSweep();

  @override
  State<_RainbowSweep> createState() => _RainbowSweepState();
}

class _RainbowSweepState extends State<_RainbowSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(-2 + _c.value * 4, -1),
            end: Alignment(-1 + _c.value * 4, 1),
            colors: const [
              Colors.transparent,
              Color(0x33FF3D78),
              Color(0x44FFD54F),
              Color(0x334CCF7D),
              Color(0x334FA3FF),
              Colors.transparent,
            ],
          ).createShader(rect),
          child: Container(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
    );
  }
}