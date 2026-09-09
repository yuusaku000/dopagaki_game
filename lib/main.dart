import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'data/theme.dart';
import 'models/dopaminer.dart';
import 'models/save_data.dart';
import 'screens/create_screen.dart';
import 'screens/deck_list_screen.dart';
import 'screens/dopaminer_list_screen.dart';
import 'screens/dungeon_screen.dart';
import 'screens/gacha_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tutorial_screen.dart';
import 'widgets/city_bg.dart';
import 'widgets/chara.dart';

/// アプリ全体で共有するセーブデータ。
/// 画面数がまだ少ないので、ひとまずグローバルに1つ持つ。
final save = SaveData();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await save.load();
  runApp(const DopagakiApp());
}

class DopagakiApp extends StatelessWidget {
  const DopagakiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ドパガキ育成',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.dopa,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Hiragino Kaku Gothic ProN',
      ),
      home: const HomeScreen(),
    );
  }
}

// =====================================================================
// ホーム画面
// =====================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Map<String, List<String>> _lines = {
    'high': ['今日もヒマだなあ', '外で遊んでこようかな', '宿題やった？って聞かないで', 'おなかすいた'],
    'mid': ['ちょっとだけ動画見よ', 'スマホどこ置いたっけ', 'なんか疲れてる気がする', '明日学校か…'],
    'low': ['……', 'あと1本だけ見る', '通知きてないかな', 'べつに、なんでもない'],
    'none': ['まだ誰も育ててないよ', 'はじめる？', 'スマホ、買ってくれる？'],
  };

  final _rand = Random();
  String _say = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    save.addListener(_onSaveChanged);
    _talk();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) => _talk());
  }

  @override
  void dispose() {
    _timer?.cancel();
    save.removeListener(_onSaveChanged);
    super.dispose();
  }

  void _onSaveChanged() {
    if (mounted) setState(() {});
  }

  void _talk() {
    final last = save.dopaminers.isEmpty ? null : save.dopaminers.last;
    final key = last == null
        ? 'none'
        : last.human >= 55
            ? 'high'
            : last.human >= 30
                ? 'mid'
                : 'low';
    final pool = _lines[key]!;
    if (mounted) setState(() => _say = pool[_rand.nextInt(pool.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final last = save.dopaminers.isEmpty ? null : save.dopaminers.last;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Expanded(child: _hero(last)),
                _dock(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- 上半分：背景とキャラ ----------
  Widget _hero(Dopaminer? last) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const NightCityBackground(),
        const TwinkleLayer(),
        _heroContent(last),
      ],
    );
  }

  Widget _heroContent(Dopaminer? last) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ドパガキ育成',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.1)),
                  Text('D O P A G A K I',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3,
                          color: C.txt.withValues(alpha: 0.55))),
                ],
              ),
              const Spacer(),
              _pill('🎫 ${save.tickets}', C.gold),
              const SizedBox(width: 8),
              _circleBtn('？', () => _open(const TutorialScreen())),
              const SizedBox(width: 6),
              _circleBtn('⚙', () => _open(SettingsScreen(save: save))),
            ],
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _talk,
                  child: _bubble(_say),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: CharaView(
                    look: last?.look ?? Look(),
                    human: last?.human ?? 70,
                    dopa: last?.dopa ?? 0,
                    size: CharaSize.hero,
                  ),
                ),
              ],
            ),
          ),
          if (last != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(last.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                        color: C.gold, borderRadius: BorderRadius.circular(6)),
                    child: Text(last.rank,
                        style: const TextStyle(
                            color: Color(0xFF3A2C00),
                            fontWeight: FontWeight.w900,
                            fontSize: 11)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: Wrap(
              spacing: 7,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _stat('育成済み', '${save.dopaminers.length}人'),
                if (last != null) _stat('最高スコア', '${save.bestScore}'),
                _stat('⚔ 最高到達', '${save.bestFloor}F'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 下半分：メニュー ----------
  Widget _dock() {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: C.panel,
          border: Border(top: BorderSide(color: C.line)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startRun,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  backgroundColor: const Color(0xFFFF5C8D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('▶ 育成をはじめる',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                _menuBtn('🃏', 'デッキ', () => _open(DeckListScreen(save: save))),
                const SizedBox(width: 9),
                _menuBtn('👥', 'ドパミナー', () => _open(DopaminerListScreen(save: save))),
                const SizedBox(width: 9),
                _menuBtn('🎰', 'ガチャ', () => _open(GachaScreen(save: save)),
                    badge: save.tickets > 0 || save.fragments >= 10),
                const SizedBox(width: 9),
                _menuBtn('⚔', 'ドパガキ道', () => _open(DungeonScreen(save: save))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 部品 ----------
  Widget _bubble(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 4))
        ],
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Color(0xFF221C2C), fontSize: 12.5, height: 1.5)),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2114),
          border: Border.all(color: const Color(0xFF5C4620)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      );

  Widget _stat(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          border: Border.all(color: C.line),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text.rich(TextSpan(children: [
          TextSpan(
              text: '$label ',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFFD8C6EC))),
          TextSpan(
              text: value,
              style: const TextStyle(
                  fontSize: 10.5,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ])),
      );

  Widget _circleBtn(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border.all(color: C.line),
            shape: BoxShape.circle,
          ),
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
      );

  Widget _menuBtn(String icon, String label, VoidCallback onTap,
      {bool badge = false}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 11, 4, 9),
          decoration: BoxDecoration(
            color: C.panel2,
            border: Border.all(color: C.line),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 21)),
                  const SizedBox(height: 5),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10.5,
                          color: C.sub,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              if (badge)
                Positioned(
                  right: -2,
                  top: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: C.dopa, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  void _startRun() => _open(CreateScreen(save: save));
}