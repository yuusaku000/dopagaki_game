import 'package:flutter/material.dart';

import '../data/theme.dart';
import '../models/save_data.dart';
import '../widgets/confirm.dart';
import '../widgets/chara.dart';
import 'deck_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  final SaveData save;
  const SettingsScreen({super.key, required this.save});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SaveData get save => widget.save;

  Future<void> _toggle(void Function() change) async {
    setState(change);
    await save.commit();
  }

  @override
  Widget build(BuildContext context) {
    final s = save.settings;
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
                    BackChip(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 10),
                    const Text('設定',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 14),
                  _switchRow('カード効果を数値で表示', s.showEffect,
                      () => _toggle(() => s.showEffect = !s.showEffect)),
                  _switchRow('セリフを表示', s.showLine,
                      () => _toggle(() => s.showLine = !s.showLine)),
                  _switchRow('演出（振動・フラッシュ）', s.anim,
                      () => _toggle(() => s.anim = !s.anim)),
                  const SizedBox(height: 20),
                  _infoCard(),
                  const Spacer(),
                  const Text(
                    'セーブデータはこの端末に保存されます。',
                    style: TextStyle(fontSize: 11, color: C.sub, height: 1.8),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _wipe,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: C.txt,
                        backgroundColor: C.panel2,
                        side: const BorderSide(color: C.line),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('セーブデータを削除',
                          style: TextStyle(
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

  Widget _switchRow(String label, bool value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: C.panel,
            border: Border.all(color: C.line),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 13))),
              Switch(
                value: value,
                onChanged: (_) => onTap(),
                thumbColor: const WidgetStatePropertyAll(Colors.white),
                trackColor: WidgetStateProperty.resolveWith(
                  (st) => st.contains(WidgetState.selected)
                      ? C.dopa
                      : const Color(0xFF3A3050),
                ),
                trackOutlineColor:
                    const WidgetStatePropertyAll(Colors.transparent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 現在の所持状況をまとめて確認できる欄
  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: C.panel,
        border: Border.all(color: C.line),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('現在の状況',
              style: TextStyle(
                  fontSize: 12.5, color: C.sub, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _infoRow('ドパミナー', '${save.dopaminers.length}人'),
          _infoRow('チケット', '🎫 ${save.tickets}'),
          _infoRow('かけら', '🧩 ${save.fragments} / 10'),
          _infoRow('所持SDカード', '${save.ownedSd.length}種'),
          _infoRow('ドパガキ道の最高到達', '${save.bestFloor}F'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: C.sub)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Future<void> _wipe() async {
    final ok = await askConfirm(
      context,
      icon: '🗑',
      title: 'セーブデータを削除しますか？',
      description: 'ドパミナー・カード・かけらがすべて消えます。\nこの操作は取り消せません。',
      yesLabel: '削除する',
    );
    if (!ok) return;
    await save.wipe();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}