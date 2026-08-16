import 'package:cockpit/app/core/ui/themes/themes.dart';
import 'package:cockpit/app/core/ui/widgets/hover_tap.dart';
import 'package:flutter/widgets.dart';

/// Barra de teclas acessórias do terminal no MOBILE (plano 60, Wave F): ancorada
/// acima do teclado virtual, dá as teclas que o teclado do SO não tem (ESC, Tab,
/// setas, Ctrl+C, F1–F12). Cada toque envia a sequência de controle crua ao
/// terminal ativo via [onKeys]. Um toggle "Fn" troca a linha default pelas
/// F-keys.
class TerminalKeyBar extends StatefulWidget {
  const TerminalKeyBar({super.key, required this.onKeys});

  /// Envia os bytes da tecla ao terminal ativo (a VM roteia pra aba focada).
  final void Function(List<int> bytes) onKeys;

  @override
  State<TerminalKeyBar> createState() => _TerminalKeyBarState();
}

class _TerminalKeyBarState extends State<TerminalKeyBar> {
  bool _fn = false;

  // Sequências VT (xterm). Setas/F1–F4 em modo aplicação (ESC O x); F5+ em
  // ESC [ n ~ — cobre bash/vim/claude sem depender do modo do cursor.
  static const _esc = <int>[0x1b];
  static const _tab = <int>[0x09];
  static const _ctrlC = <int>[0x03];
  static const _up = <int>[0x1b, 0x5b, 0x41]; // ESC [ A
  static const _down = <int>[0x1b, 0x5b, 0x42];
  static const _right = <int>[0x1b, 0x5b, 0x43];
  static const _left = <int>[0x1b, 0x5b, 0x44];

  static const Map<String, List<int>> _fkeys = <String, List<int>>{
    'F1': [0x1b, 0x4f, 0x50],
    'F2': [0x1b, 0x4f, 0x51],
    'F3': [0x1b, 0x4f, 0x52],
    'F4': [0x1b, 0x4f, 0x53],
    'F5': [0x1b, 0x5b, 0x31, 0x35, 0x7e],
    'F6': [0x1b, 0x5b, 0x31, 0x37, 0x7e],
    'F7': [0x1b, 0x5b, 0x31, 0x38, 0x7e],
    'F8': [0x1b, 0x5b, 0x31, 0x39, 0x7e],
    'F9': [0x1b, 0x5b, 0x32, 0x30, 0x7e],
    'F10': [0x1b, 0x5b, 0x32, 0x31, 0x7e],
    'F11': [0x1b, 0x5b, 0x32, 0x33, 0x7e],
    'F12': [0x1b, 0x5b, 0x32, 0x34, 0x7e],
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final keys = <Widget>[
      if (!_fn) ...[
        _key('esc', _esc),
        _key('tab', _tab),
        _key('⌃C', _ctrlC),
        _key('←', _left),
        _key('↑', _up),
        _key('↓', _down),
        _key('→', _right),
      ] else ...[
        for (final e in _fkeys.entries) _key(e.key, e.value),
      ],
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            // Toggle Fn/abc fixo à esquerda.
            _toggle(),
            Container(width: 1, height: 22, color: colors.border),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                children: [
                  for (final k in keys)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 6,
                      ),
                      child: k,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: _cap(_fn ? 'abc' : 'Fn', onTap: () => setState(() => _fn = !_fn)),
  );

  Widget _key(String label, List<int> bytes) =>
      _cap(label, onTap: () => widget.onKeys(bytes));

  Widget _cap(String label, {required VoidCallback onTap}) {
    final colors = context.colors;
    return HoverTap(
      onTap: onTap,
      color: colors.panel3,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minWidth: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          label,
          style: context.typo.mono.copyWith(fontSize: 13, color: colors.text),
        ),
      ),
    );
  }
}
