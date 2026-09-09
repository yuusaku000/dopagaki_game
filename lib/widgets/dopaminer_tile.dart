import 'package:flutter/material.dart';

import '../data/cards.dart';
import '../data/theme.dart';
import '../models/dopaminer.dart';
import 'chara.dart';

/// 並び替えの種類
enum SortKey { newest, score, dopa, brain, human, name }

const Map<SortKey, String> kSortLabels = {
  SortKey.newest: '新しい順',
  SortKey.score: 'スコア順',
  SortKey.dopa: 'ドパ欲順',
  SortKey.brain: '頭脳順',
  SortKey.human: '人間性順',
  SortKey.name: '名前順',
};

/// 元の並び順のインデックスを、指定キーで並べ替えて返す
List<int> sortedIndices(List<Dopaminer> list, SortKey key) {
  final idx = List.generate(list.length, (i) => i);
  switch (key) {
    case SortKey.newest:
      return idx.reversed.toList();
    case SortKey.name:
      idx.sort((a, b) => list[a].name.compareTo(list[b].name));
    case SortKey.score:
      idx.sort((a, b) => list[b].score.compareTo(list[a].score));
    case SortKey.dopa:
      idx.sort((a, b) => list[b].dopa.compareTo(list[a].dopa));
    case SortKey.brain:
      idx.sort((a, b) => list[b].brain.compareTo(list[a].brain));
    case SortKey.human:
      idx.sort((a, b) => list[b].human.compareTo(list[a].human));
  }
  return idx;
}

/// 並び替えプルダウン
class SortDropdown extends StatelessWidget {
  final SortKey value;
  final ValueChanged<SortKey> onChanged;
  final String? trailing;

  const SortDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('並び替え', style: TextStyle(fontSize: 11, color: C.sub)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: C.panel,
            border: Border.all(color: C.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<SortKey>(
            value: value,
            underline: const SizedBox.shrink(),
            dropdownColor: C.panel2,
            isDense: true,
            style: const TextStyle(fontSize: 12.5, color: C.txt),
            items: kSortLabels.entries
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(trailing!, style: const TextStyle(fontSize: 11, color: C.sub)),
      ],
    );
  }
}

/// ランクのバッジ
class RankBadge extends StatelessWidget {
  final String rank;
  const RankBadge(this.rank, {super.key});

  static const _colors = {
    'C': [Color(0xFF3A3350), Color(0xFFB8AED6)],
    'B': [Color(0xFF2B4A3A), Color(0xFF8FE0B4)],
    'A': [Color(0xFF2B3A5C), Color(0xFF9DC0FF)],
    'S': [Color(0xFF5C3A12), Color(0xFFFFCF8A)],
    'SS': [Color(0xFF7A2050), Color(0xFFFFD9EC)],
    '圏外': [Color(0xFF3A2028), Color(0xFFE08A9A)],
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[rank] ?? _colors['C']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration:
          BoxDecoration(color: c[0], borderRadius: BorderRadius.circular(5)),
      child: Text(rank,
          style: TextStyle(
              fontSize: 10, color: c[1], fontWeight: FontWeight.w900)),
    );
  }
}

/// 一覧・選択画面で使うドパミナーのカード。
/// trailing に「お別れ」などのボタンを重ねられる。
class DopaminerTile extends StatelessWidget {
  final Dopaminer d;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// ダンジョン用の表示（攻撃力など）に切り替える
  final bool battleMode;

  const DopaminerTile({
    super.key,
    required this.d,
    this.selected = false,
    this.onTap,
    this.trailing,
    this.battleMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(11, 11, trailing != null ? 56 : 11, 11),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2A1C2A) : C.panel,
              border: Border.all(color: selected ? C.dopa : C.line),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                CharaView(
                    look: d.look, human: d.human, dopa: d.dopa, size: CharaSize.tile),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(d.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        RankBadge(d.rank),
                        if (d.seed) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                                color: const Color(0xFF3A2B52),
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text('初期',
                                style: TextStyle(
                                    fontSize: 9, color: Color(0xFFC9A8FF))),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 5),
                      if (battleMode)
                        Text(
                          '攻撃力 ${d.atk} ／ 頻度 ${d.rate.toStringAsFixed(2)} ／ HP ${d.maxHp}',
                          style: const TextStyle(fontSize: 11, color: C.sub),
                        )
                      else ...[
                        Wrap(spacing: 5, runSpacing: 4, children: [
                          _chip('★ ${d.score}', C.gold),
                          _chip('頭 ${d.brain}', C.brain),
                          _chip('ド ${d.dopa}', C.dopa),
                          _chip('人 ${d.human}', C.human),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          'カード ${d.cards.map((e) => cardById(e).title).join(' / ')}',
                          style:
                              const TextStyle(fontSize: 10.5, color: C.sub),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (trailing != null)
          Positioned(
            right: 9,
            top: 0,
            bottom: 0,
            child: Center(child: trailing!),
          ),
      ],
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF171122),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10.5, color: color, fontWeight: FontWeight.bold)),
      );
}