import 'package:flutter/material.dart';

import '../data/theme.dart';
import '../models/dopaminer.dart';
import '../models/save_data.dart';
import '../widgets/confirm.dart';
import '../widgets/dopaminer_tile.dart';
import 'deck_list_screen.dart';

class DopaminerListScreen extends StatefulWidget {
  final SaveData save;
  const DopaminerListScreen({super.key, required this.save});

  @override
  State<DopaminerListScreen> createState() => _DopaminerListScreenState();
}

class _DopaminerListScreenState extends State<DopaminerListScreen> {
  SortKey sort = SortKey.newest;

  SaveData get save => widget.save;

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
                    BackChip(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 10),
                    const Text('ドパミナー一覧',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  SortDropdown(
                    value: sort,
                    onChanged: (v) => setState(() => sort = v),
                    trailing: '${save.dopaminers.length}人',
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _list()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list() {
    if (save.dopaminers.isEmpty) {
      return const Center(
        child: Text('まだ誰も育てていません。',
            style: TextStyle(fontSize: 13, color: C.sub)),
      );
    }
    final order = sortedIndices(save.dopaminers, sort);
    return ListView.separated(
      itemCount: order.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, k) {
        final i = order[k];
        final d = save.dopaminers[i];
        return DopaminerTile(
          d: d,
          trailing: _farewellButton(i, d),
        );
      },
    );
  }

  Widget _farewellButton(int index, Dopaminer d) => InkWell(
        onTap: () => _farewell(index, d),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF331A24),
            border: Border.all(color: const Color(0xFF6B2436)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('🕊', style: TextStyle(fontSize: 16)),
        ),
      );

  Future<void> _farewell(int index, Dopaminer d) async {
    final ok = await askConfirm(
      context,
      icon: '🕊',
      title: '${d.name} とお別れしますか？',
      description: 'スコア ${d.score}／${d.rank}ランク\nこの操作は取り消せません。',
      yesLabel: 'お別れする',
    );
    if (!ok) return;
    save.dopaminers.removeAt(index);
    await save.commit();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${d.name} とお別れしました'),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ));
  }
}