import 'package:flutter/material.dart';

import '../data/theme.dart';
import '../models/dopaminer.dart';
import '../widgets/chara.dart';

class _Page {
  final String title;
  final String body;
  final String icon;
  final List<(String, Color)> points;

  const _Page({
    required this.title,
    required this.body,
    required this.icon,
    this.points = const [],
  });
}

const List<_Page> _pages = [
  _Page(
    icon: '📱',
    title: 'これはどんなゲーム？',
    body: '小学4年生でスマホを与えられた子を、'
        '中学入学までの3年間＝36ターンかけて育てます。\n\n'
        'あなたの目的は、その子を「ドパガキ」に仕上げること。'
        'つまり、ドーパミンなしでは生きられない脳を作ることです。',
  ),
  _Page(
    icon: '📊',
    title: '3つのステータス',
    body: '毎ターン選ぶカードで、3つの数値が上下します。',
    points: [
      ('頭脳 … 学年末テストの合格に必要', C.brain),
      ('ドパ欲 … 最終スコアの主役。高いほど良い', C.dopa),
      ('人間性 … 0になると育成失敗', C.human),
    ],
  ),
  _Page(
    icon: '🃏',
    title: '毎ターン、3枚から1枚を選ぶ',
    body: 'ショート動画はドパ欲が跳ね上がりますが、人間性が削れます。'
        '塾は頭脳が伸びますが、人間性がもっと削れます。\n\n'
        '外で遊ばせれば人間性は回復しますが、'
        'その1ターンはドパ欲がほとんど伸びません。'
        '36ターンしかないので、何を捨てるかを選ぶことになります。',
  ),
  _Page(
    icon: '📝',
    title: '学年末テスト',
    body: '12・24・36ターン目にテストがあります。'
        '頭脳が合格ラインに届いていれば合格です。',
    points: [
      ('合格すると ドパ欲の倍率が上がる', C.gold),
      ('4年で合格 → SD枠が2枚 解禁', C.sd),
      ('5年で合格 → SD枠が すべて解禁', C.sd),
      ('落ちても育成は続く（報酬がないだけ）', C.sub),
    ],
  ),
  _Page(
    icon: '🎴',
    title: 'デッキを組む',
    body: '育成で出てくるカードは、あらかじめ組んだデッキから抽選されます。\n\n'
        'D枠12枚とSD枠4枚の計16枚。同じカードは3枚まで積めます。'
        '3枚積めばそれだけ出やすくなるので、'
        '何を濃くするかが構築の肝です。',
  ),
  _Page(
    icon: '👥',
    title: 'ドパミナー',
    body: '育て終わったドパガキは「ドパミナー」として残ります。'
        '次の育成に最大2人まで連れて行けます。\n\n'
        '連れて行くと初期値が上がり、'
        'その子が育成中によく使ったカード2枚が抽選に追加されます。'
        '周回するほど強くなっていく仕組みです。',
  ),
  _Page(
    icon: '🎰',
    title: 'ガチャとドパガキ道',
    body: '育成完了やダンジョン攻略でチケットが手に入り、'
        'ガチャでSDカードやキャラメイクのパーツが引けます。\n\n'
        'ドパガキ道はドパミナー3人で潜るオート戦闘です。'
        '頭脳が攻撃頻度、ドパ欲が攻撃力と耐久になります。'
        '人間性は戦闘に一切関与しません。',
  ),
  _Page(
    icon: '🏆',
    title: '最終スコア',
    body: '育成が終わると、次の式でスコアが決まります。\n\n'
        '頭脳 × 3 ＋ 人間性 × 5 ＋ ドパ欲 × 2\n\n'
        'ドパ欲は上限がないので、'
        '実質ここをどこまで伸ばせるかの勝負になります。\n\n'
        'では、良いドパガキを。',
  ),
];

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

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
                children: [
                  Row(children: [
                    const Text('あそびかた',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: C.sub),
                      child: const Text('スキップ',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) => _pageView(_pages[i]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _dots(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.dopa,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(_isLast ? 'はじめる' : 'つぎへ',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageView(_Page p) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(p.icon,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text(p.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: C.panel,
              border: Border.all(color: C.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.body,
                    style: const TextStyle(fontSize: 13, height: 1.9)),
                if (p.points.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...p.points.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 6, right: 9),
                              decoration: BoxDecoration(
                                  color: e.$2, shape: BoxShape.circle),
                            ),
                            Expanded(
                              child: Text(e.$1,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: e.$2,
                                      height: 1.6,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          // 最後のページだけキャラを出す
          if (p.title == '最終スコア') ...[
            const SizedBox(height: 10),
            Center(
              child: CharaView(
                  look: Look(hair: 2, hairColor: 4, cloth: 1),
                  human: 18,
                  dopa: 600,
                  size: CharaSize.preview),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _pages.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == _index ? 18 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == _index ? C.dopa : const Color(0xFF3A3050),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
}