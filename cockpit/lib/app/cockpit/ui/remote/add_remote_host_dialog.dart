import 'package:cockpit/app/core/ui/themes/themes.dart';
import 'package:cockpit/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Resultado do dialog "Add remote host": nome de exibição + destino SSH.
class RemoteHostDraft {
  const RemoteHostDraft({required this.name, required this.sshTarget});
  final String name;
  final String sshTarget;
}

/// Dialog "Add remote host" (plano 58, Wave 2): coleta nome + `user@host`.
/// Sem validação de conectividade aqui — o teste é a conexão real ao abrir o
/// pin (que já mostra loading/erro tipado).
Future<RemoteHostDraft?> showAddRemoteHostDialog(
  BuildContext context, {
  String? initialName,
  String? initialSshTarget,
  bool edit = false,
}) {
  return showDialog<RemoteHostDraft>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (context) => _AddRemoteHostDialog(
      initialName: initialName,
      initialSshTarget: initialSshTarget,
      edit: edit,
    ),
  );
}

class _AddRemoteHostDialog extends StatefulWidget {
  const _AddRemoteHostDialog({
    this.initialName,
    this.initialSshTarget,
    this.edit = false,
  });

  final String? initialName;
  final String? initialSshTarget;
  final bool edit;

  @override
  State<_AddRemoteHostDialog> createState() => _AddRemoteHostDialogState();
}

class _AddRemoteHostDialogState extends State<_AddRemoteHostDialog> {
  late final _name = TextEditingController(text: widget.initialName ?? '');
  late final _ssh = TextEditingController(text: widget.initialSshTarget ?? '');

  @override
  void dispose() {
    _name.dispose();
    _ssh.dispose();
    super.dispose();
  }

  String get _sshTrimmed => _ssh.text.trim();
  String get _nameTrimmed => _name.text.trim();

  // SSH obrigatório; nome default = o próprio target se vazio.
  bool get _valid => _sshTrimmed.isNotEmpty;

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop(
      RemoteHostDraft(
        name: _nameTrimmed.isEmpty ? _sshTrimmed : _nameTrimmed,
        sshTarget: _sshTrimmed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.t.cockpit.remoteHost;
    return AlertDialog(
      title: Text(
        widget.edit ? tr.editHost : tr.addHost,
        style: context.typo.title.copyWith(fontSize: 15, color: colors.text),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ssh,
              autofocus: true,
              placeholder: Text(tr.sshTarget),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              placeholder: Text(tr.hostName),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        OutlineButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.cancel),
        ),
        PrimaryButton(
          onPressed: _valid ? _submit : null,
          child: Text(widget.edit ? context.t.common.save : context.t.common.add),
        ),
      ],
    );
  }
}
