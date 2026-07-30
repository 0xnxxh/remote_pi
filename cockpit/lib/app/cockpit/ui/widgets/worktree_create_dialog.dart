import 'package:cockpit/app/cockpit/domain/contracts/worktree_manager.dart';
import 'package:cockpit/app/cockpit/domain/validators/worktree_name_validator.dart';
import 'package:cockpit/app/core/ui/themes/themes.dart';
import 'package:cockpit/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Dialog de criar worktree. Valida o nome **ao vivo** (decisões 10, 11) contra
/// o [namespace] (branches locais + worktrees existentes); Criar só acende com
/// nome válido. Ao confirmar, trava com spinner e chama [onCreate] (que roda o
/// `git worktree add` real): se devolver uma mensagem de erro, mostra inline e
/// reabre; `null` = sucesso → fecha (decisão 21).
Future<void> showWorktreeCreateDialog(
  BuildContext context, {
  required String rootName,
  required WorktreeNamespace namespace,
  required Future<String?> Function(String name) onCreate,
  // "Fork Worktree": mesmo dialog, copy própria — a base é a branch do fork
  // ([rootName]), não o HEAD do pai.
  bool fork = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (context) => _WorktreeCreateDialog(
      rootName: rootName,
      namespace: namespace,
      onCreate: onCreate,
      fork: fork,
    ),
  );
}

class _WorktreeCreateDialog extends StatefulWidget {
  const _WorktreeCreateDialog({
    required this.rootName,
    required this.namespace,
    required this.onCreate,
    required this.fork,
  });

  final String rootName;
  final bool fork;
  final WorktreeNamespace namespace;
  final Future<String?> Function(String name) onCreate;

  @override
  State<_WorktreeCreateDialog> createState() => _WorktreeCreateDialogState();
}

class _WorktreeCreateDialogState extends State<_WorktreeCreateDialog> {
  static const _validator = WorktreeNameValidator();
  final TextEditingController _name = TextEditingController();
  bool _submitting = false;
  String? _gitError; // erro do git no último submit

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  WorktreeNameCheck get _check => _validator.validate(
    _name.text,
    existingBranches: widget.namespace.branches,
    existingWorktreeNames: widget.namespace.worktreeNames,
  );

  bool get _canCreate =>
      _name.text.isNotEmpty && _check.isValid && !_submitting;

  /// Mensagem por causa de validação (null quando válido ou campo intacto).
  String? _reason(WorktreeNameCheck check) {
    final tr = context.t.cockpit.worktreeCreateDialog;
    return switch (check.error) {
      null || WorktreeNameError.empty => null,
      WorktreeNameError.whitespace => tr.errorWhitespace,
      WorktreeNameError.invalidChar => tr.errorInvalidChar,
      WorktreeNameError.invalidSequence => tr.errorInvalidSequence,
      WorktreeNameError.reserved => tr.errorReserved,
      WorktreeNameError.duplicateBranch => tr.errorDuplicateBranch,
      WorktreeNameError.duplicateWorktree => tr.errorDuplicateWorktree,
    };
  }

  Future<void> _submit() async {
    if (!_canCreate) return;
    setState(() {
      _submitting = true;
      _gitError = null;
    });
    final error = await widget.onCreate(_name.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _gitError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final check = _check;
    final reason = _gitError ?? _reason(check);
    final showError = reason != null;
    final tr = context.t.cockpit.worktreeCreateDialog;

    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.fork ? tr.forkTitle : tr.createTitle,
            style: context.typo.title.copyWith(
              fontSize: 15,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.fork
                ? tr.forkSubtitle(root: widget.rootName)
                : tr.createSubtitle(root: widget.rootName),
            style: context.typo.label.copyWith(color: colors.text3),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              enabled: !_submitting,
              onChanged: (_) => setState(() => _gitError = null),
              onSubmitted: (_) => _submit(),
              placeholder: Text(tr.namePlaceholder),
              style: context.typo.mono.copyWith(
                fontSize: 13,
                color: colors.text,
              ),
              borderRadius: BorderRadius.circular(7),
              border: showError ? Border.all(color: colors.error) : null,
            ),
            if (showError) ...[
              const SizedBox(height: 8),
              Text(
                reason,
                style: context.typo.label.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        OutlineButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(context.t.common.cancel),
        ),
        PrimaryButton(
          onPressed: _canCreate ? _submit : null,
          child: _submitting
              ? const CircularProgressIndicator(size: 16, color: Colors.white)
              : Text(widget.fork ? tr.fork : context.t.common.create),
        ),
      ],
    );
  }
}
