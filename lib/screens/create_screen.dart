import 'package:flutter/material.dart';

import '../data/theme.dart';
import '../models/dopaminer.dart';
import '../models/save_data.dart';
import '../widgets/chara.dart';
import 'deck_list_screen.dart';
import 'pick_screen.dart';

class CreateScreen extends StatefulWidget {
  final SaveData save;
  const CreateScreen({super.key, required this.save});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final Look look = Look();
  final TextEditingController _name =
      TextEditingController(text: 'ドパオ');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int _valueOf(String key) {
    switch (key) {
      case 'hair':
        return look.hair;
      case 'hairColor':
        return look.hairColor;
      case 'skin':
        return look.skin;
      case 'face':
        return look.face;
      default:
        return look.cloth;
    }
  }

  void _setValue(String key, int v) {
    setState(() {
      switch (key) {
        case 'hair':
          look.hair = v;
        case 'hairColor':
          look.hairColor = v;
        case 'skin':
          look.skin = v;
        case 'face':
          look.face = v;
        default:
          look.cloth = v;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = '${Parts.hairNames[look.hair]}／'
        '${Parts.hairColorNames[look.hairColor]}／'
        '${Parts.skinNames[look.skin]}／'
        '${Parts.faceNames[look.face]}／'
        '${Parts.clothNames[look.cloth]}';

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
                    const Text('キャラメイク',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  Center(child: CharaView(look: look, size: CharaSize.form)),
                  const SizedBox(height: 4),
                  Text(summary,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: C.sub)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('なまえ',
                              style: TextStyle(fontSize: 12, color: C.sub)),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _name,
                            maxLength: 8,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: C.panel,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: C.line),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: C.line),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          for (final key in Parts.keys) ...[
                            _partRow(key),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),
                  ),
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
                      child: const Text('つぎへ',
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

  /// パーツ選択の1行
  Widget _partRow(String key) {
    final n = Parts.count(key);
    final selected = _valueOf(key);
    final locked = List.generate(n, (i) => i)
        .where((i) => !widget.save.isPartUnlocked(key, i))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Parts.keyLabels[key]!,
            style: const TextStyle(fontSize: 12, color: C.sub)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: List.generate(n, (i) {
            final unlocked = widget.save.isPartUnlocked(key, i);
            return _partChip(key, i, unlocked, selected == i);
          }),
        ),
        if (locked > 0)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text('🔒 $locked種が未解放（ガチャで入手）',
                style: const TextStyle(fontSize: 10, color: C.sub)),
          ),
      ],
    );
  }

  Widget _partChip(String key, int i, bool unlocked, bool selected) {
    // 色パーツは色見本、形パーツは記号で表示する
    final isColor = key == 'hairColor' || key == 'skin' || key == 'cloth';
    Color? swatch;
    String label = '';
    if (isColor) {
      swatch = switch (key) {
        'hairColor' => Parts.hairColors[i],
        'skin' => Parts.skins[i],
        _ => Parts.clothes[i],
      };
    } else {
      label = key == 'hair'
          ? Parts.hairNames[i].substring(0, 2)
          : ['●', 'ー', '◡'][i];
    }

    return SizedBox(
      width: 46,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (!unlocked) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                    content: Text('🔒 このパーツはガチャで解放されます'),
                    duration: Duration(milliseconds: 1200),
                    behavior: SnackBarBehavior.floating,
                  ));
                return;
              }
              _setValue(key, i);
            },
            borderRadius: BorderRadius.circular(9),
            child: Opacity(
              opacity: unlocked ? 1 : 0.35,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: swatch ?? C.panel,
                  border: Border.all(
                    color: selected ? C.dopa : C.line,
                    width: 2,
                    style: unlocked ? BorderStyle.solid : BorderStyle.none,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(unlocked ? label : '🔒',
                    style: const TextStyle(fontSize: 12, color: C.sub)),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            unlocked ? Parts.nameOf(key, i) : '未解放',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: selected ? C.dopa : C.sub,
              fontWeight: selected ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _next() {
    final name = _name.text.trim().isEmpty ? 'ドパオ' : _name.text.trim();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PickScreen(
        save: widget.save,
        name: name,
        look: look.copy(),
      ),
    ));
  }
}