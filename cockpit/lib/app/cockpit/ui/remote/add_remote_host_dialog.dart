import 'package:cockpit/app/cockpit/domain/entities/remote_host.dart';
import 'package:cockpit/app/core/ui/themes/themes.dart';
import 'package:cockpit/i18n/strings.g.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Resultado do dialog "Add remote host": nome + endpoint SSH separado em
/// usuário/host/porta + modo de auth. [password] é `null` quando não muda
/// (auth por chave, ou edição que manteve a senha atual).
class RemoteHostDraft {
  const RemoteHostDraft({
    required this.name,
    required this.sshTarget,
    required this.port,
    required this.auth,
    this.password,
  });

  final String name;

  /// `user@host` (recombinado dos campos separados).
  final String sshTarget;
  final int port;
  final RemoteHostAuth auth;

  /// Senha nova (auth por senha). `null` = não alterar a senha guardada.
  final String? password;
}

/// Dialog "Add remote host" (plano 60, Wave C): coleta usuário, host, porta,
/// nome e modo de auth (chave/senha). Sem validação de conectividade aqui — o
/// teste é a conexão real ao abrir o pin (que já mostra loading/erro tipado).
Future<RemoteHostDraft?> showAddRemoteHostDialog(
  BuildContext context, {
  String? initialName,
  String? initialSshTarget,
  int initialPort = 22,
  RemoteHostAuth initialAuth = RemoteHostAuth.key,
  bool hasStoredPassword = false,
  bool edit = false,
}) {
  return showDialog<RemoteHostDraft>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (context) => _AddRemoteHostDialog(
      initialName: initialName,
      initialSshTarget: initialSshTarget,
      initialPort: initialPort,
      initialAuth: initialAuth,
      hasStoredPassword: hasStoredPassword,
      edit: edit,
    ),
  );
}

class _AddRemoteHostDialog extends StatefulWidget {
  const _AddRemoteHostDialog({
    this.initialName,
    this.initialSshTarget,
    this.initialPort = 22,
    this.initialAuth = RemoteHostAuth.key,
    this.hasStoredPassword = false,
    this.edit = false,
  });

  final String? initialName;
  final String? initialSshTarget;
  final int initialPort;
  final RemoteHostAuth initialAuth;
  final bool hasStoredPassword;
  final bool edit;

  @override
  State<_AddRemoteHostDialog> createState() => _AddRemoteHostDialogState();
}

class _AddRemoteHostDialogState extends State<_AddRemoteHostDialog> {
  late final _user = TextEditingController(text: _splitUser());
  late final _host = TextEditingController(text: _splitHost());
  late final _port = TextEditingController(text: widget.initialPort.toString());
  late final _name = TextEditingController(text: widget.initialName ?? '');
  late final _password = TextEditingController();
  late RemoteHostAuth _auth = widget.initialAuth;

  String _splitUser() {
    final t = widget.initialSshTarget ?? '';
    final at = t.indexOf('@');
    return at <= 0 ? '' : t.substring(0, at);
  }

  String _splitHost() {
    final t = widget.initialSshTarget ?? '';
    final at = t.indexOf('@');
    return at < 0 ? t : t.substring(at + 1);
  }

  @override
  void dispose() {
    _user.dispose();
    _host.dispose();
    _port.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _userTrimmed => _user.text.trim();
  String get _hostTrimmed => _host.text.trim();
  String get _nameTrimmed => _name.text.trim();

  // Usuário e host obrigatórios; porta cai em 22 se inválida. Com auth por
  // senha, exige senha — exceto ao editar mantendo a já guardada.
  bool get _valid {
    if (_userTrimmed.isEmpty || _hostTrimmed.isEmpty) return false;
    if (_auth == RemoteHostAuth.password &&
        _password.text.isEmpty &&
        !widget.hasStoredPassword) {
      return false;
    }
    return true;
  }

  void _submit() {
    if (!_valid) return;
    final target = '$_userTrimmed@$_hostTrimmed';
    final port = int.tryParse(_port.text.trim()) ?? 22;
    Navigator.of(context).pop(
      RemoteHostDraft(
        name: _nameTrimmed.isEmpty ? target : _nameTrimmed,
        sshTarget: target,
        port: port,
        auth: _auth,
        // Senha vazia num edit que já tinha senha = manter a guardada (null).
        password: _auth == RemoteHostAuth.password && _password.text.isNotEmpty
            ? _password.text
            : null,
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
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usuário + host lado a lado; porta estreita à direita.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _user,
                    autofocus: true,
                    placeholder: Text(tr.userLabel),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _host,
                    placeholder: Text(tr.hostLabel),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _port,
                    placeholder: Text(tr.portLabel),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              placeholder: Text(tr.hostName),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            // Modo de autenticação.
            Text(
              tr.authLabel,
              style: context.typo.label.copyWith(color: colors.text2),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _AuthChip(
                  label: tr.authKey,
                  selected: _auth == RemoteHostAuth.key,
                  onTap: () => setState(() => _auth = RemoteHostAuth.key),
                ),
                const SizedBox(width: 8),
                _AuthChip(
                  label: tr.authPassword,
                  selected: _auth == RemoteHostAuth.password,
                  onTap: () => setState(() => _auth = RemoteHostAuth.password),
                ),
              ],
            ),
            if (_auth == RemoteHostAuth.password) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _password,
                obscureText: true,
                placeholder: Text(
                  widget.hasStoredPassword ? tr.passwordKeep : tr.passwordLabel,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ],
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
          child: Text(
            widget.edit ? context.t.common.save : context.t.common.add,
          ),
        ),
      ],
    );
  }
}

/// Botão-toggle do modo de auth (chave/senha).
class _AuthChip extends StatelessWidget {
  const _AuthChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return PrimaryButton(
        size: ButtonSize.small,
        onPressed: onTap,
        child: Text(label),
      );
    }
    return OutlineButton(
      size: ButtonSize.small,
      onPressed: onTap,
      child: Text(label),
    );
  }
}
