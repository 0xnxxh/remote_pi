import 'package:cockpit/app/core/ui/themes/themes.dart';
import 'package:cockpit/app/core/ui/widgets/hover_tap.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter/widgets.dart';

/// Barra de teclas acessórias do terminal no MOBILE (plano 60, Wave F): ancorada
/// acima do teclado virtual, dá as teclas que o teclado do SO não tem (ESC, Tab,
/// setas, Ctrl+C, F1–F12). Todas numa linha ROLÁVEL (não cabem numa tela
/// estreita). À esquerda, fixo, o botão de baixar o teclado.
class TerminalKeyBar extends StatelessWidget {
  const TerminalKeyBar({super.key, required this.onKeys});

  /// Envia os bytes da tecla ao terminal ativo (a VM roteia pra aba focada).
  final void Function(List<int> bytes) onKeys;

  // Sequências VT (xterm). Setas/F1–F4 em modo aplicação (ESC O x); F5+ em
  // ESC [ n ~ — cobre bash/vim/claude sem depender do modo do cursor.
  static const List<(String, List<int>)> _keys = <(String, List<int>)>[
    ('esc', [0x1b]),
    ('tab', [0x09]),
    ('⌃C', [0x03]),
    ('←', [0x1b, 0x5b, 0x44]),
    ('↑', [0x1b, 0x5b, 0x41]),
    ('↓', [0x1b, 0x5b, 0x42]),
    ('→', [0x1b, 0x5b, 0x43]),
    ('F1', [0x1b, 0x4f, 0x50]),
    ('F2', [0x1b, 0x4f, 0x51]),
    ('F3', [0x1b, 0x4f, 0x52]),
    ('F4', [0x1b, 0x4f, 0x53]),
    ('F5', [0x1b, 0x5b, 0x31, 0x35, 0x7e]),
    ('F6', [0x1b, 0x5b, 0x31, 0x37, 0x7e]),
    ('F7', [0x1b, 0x5b, 0x31, 0x38, 0x7e]),
    ('F8', [0x1b, 0x5b, 0x31, 0x39, 0x7e]),
    ('F9', [0x1b, 0x5b, 0x32, 0x30, 0x7e]),
    ('F10', [0x1b, 0x5b, 0x32, 0x31, 0x7e]),
    ('F11', [0x1b, 0x5b, 0x32, 0x33, 0x7e]),
    ('F12', [0x1b, 0x5b, 0x32, 0x34, 0x7e]),
  ];

  void _hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            // Baixar o teclado (fixo à esquerda).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: HoverTap(
                onTap: _hideKeyboard,
                color: colors.panel3,
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 40,
                  child: Icon(
                    Icons.keyboard_hide_outlined,
                    size: 19,
                    color: colors.text2,
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 22, color: colors.border),
            // Teclas — linha rolável (não cabem numa tela estreita).
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                children: [
                  for (final (label, bytes) in _keys)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 6,
                      ),
                      child: _cap(context, label, () => onKeys(bytes)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cap(BuildContext context, String label, VoidCallback onTap) {
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
