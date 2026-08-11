import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Túnel SSH para o socket do `cockpit-server` de um host remoto (plano 58,
/// Wave 2, decisão G): usa o binário `ssh` DO SISTEMA — nada de biblioteca
/// SSH nem crypto nossa. `~/.ssh/config`, chaves, agent e ProxyJump valem de
/// graça; se `ssh <target>` funciona no terminal do usuário, funciona aqui.
///
/// O forward é de socket UDS→UDS: o servidor remoto escuta só em localhost
/// (nunca expõe porta de rede) e este túnel materializa aquele socket num
/// path local. Pro cliente, o resultado é indistinguível do loopback.
class SshTunnel {
  SshTunnel._(this._process, this.localSocketPath, this.target);

  final Process _process;

  /// Socket local que espelha o socket remoto do cockpit-server.
  final String localSocketPath;
  final String target;

  final Completer<void> _closed = Completer();

  /// Completa quando o túnel cair (queda de rede, ssh morto). Quem observa
  /// decide reconectar (banner "reconnecting" na UI, decisão de UX da W2).
  Future<void> get closed => _closed.future;

  bool get isOpen => !_closed.isCompleted;

  /// Sobe o túnel e espera o socket local ficar conectável.
  ///
  /// `BatchMode=yes`: falha alto se o ssh precisar de senha interativa (a UI
  /// mostra o erro tipado; a correção é o usuário configurar chave/agent).
  static Future<SshTunnel> open({
    required String target,
    String remoteSocketPath = r'$HOME/.cockpit/cockpit-server.sock',
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final localPath =
        '${Directory.systemTemp.path}/cockpit-ssh-'
        '${DateTime.now().microsecondsSinceEpoch}.sock';

    // O forward streamlocal do OpenSSH NÃO resolve path relativo nem expande
    // `~`/`$HOME` — precisa de path absoluto. Resolvemos a home remota com um
    // exec rápido antes de abrir o túnel.
    var resolvedRemote = remoteSocketPath;
    if (remoteSocketPath.contains(r'$HOME')) {
      final result = await Process.run('ssh', [
        '-o',
        'BatchMode=yes',
        target,
        r'printf %s "$HOME"',
      ]);
      if (result.exitCode != 0) {
        throw SshTunnelException((result.stderr as String).trim());
      }
      resolvedRemote = remoteSocketPath.replaceFirst(
        r'$HOME',
        (result.stdout as String).trim(),
      );
    }

    final process = await Process.start('ssh', [
      '-N', // só forward, sem shell
      '-o', 'BatchMode=yes',
      '-o', 'ExitOnForwardFailure=yes',
      '-o', 'ServerAliveInterval=10',
      '-o', 'ServerAliveCountMax=3',
      '-o', 'StreamLocalBindUnlink=yes',
      '-L', '$localPath:$resolvedRemote',
      target,
    ]);

    final stderrBuffer = StringBuffer();
    process.stderr.transform(utf8.decoder).listen(stderrBuffer.write);
    unawaited(process.stdout.drain<void>());

    final tunnel = SshTunnel._(process, localPath, target);
    unawaited(
      process.exitCode.then((_) {
        if (!tunnel._closed.isCompleted) tunnel._closed.complete();
      }),
    );

    // Pronto = socket local existe E o ssh não morreu. Não dá pra "testar"
    // conectando aqui: o forward UDS só valida o lado remoto na 1ª conexão
    // de verdade, então erros de destino aparecem na conexão do protocolo.
    final deadline = DateTime.now().add(timeout);
    while (!File(localPath).existsSync()) {
      if (tunnel._closed.isCompleted) {
        throw SshTunnelException(stderrBuffer.toString().trim());
      }
      if (DateTime.now().isAfter(deadline)) {
        process.kill();
        throw SshTunnelException(
          'timeout waiting for tunnel; ${stderrBuffer.toString().trim()}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return tunnel;
  }

  /// Executa um comando no host remoto pelo MESMO ssh do sistema (usado pelo
  /// bootstrap "Install server"). Retorna (exitCode, stderr).
  static Future<(int, String)> run(
    String target,
    String command, {
    List<int>? stdinBytes,
  }) async {
    final process = await Process.start('ssh', [
      '-o',
      'BatchMode=yes',
      target,
      command,
    ]);
    if (stdinBytes != null) {
      process.stdin.add(stdinBytes);
    }
    await process.stdin.close();
    final stderrText = await process.stderr.transform(utf8.decoder).join();
    unawaited(process.stdout.drain<void>());
    final code = await process.exitCode;
    return (code, stderrText.trim());
  }

  Future<void> close() async {
    _process.kill();
    await _closed.future;
    try {
      File(localSocketPath).deleteSync();
    } catch (_) {
      // já removido.
    }
  }
}

/// Erro de transporte SSH. `detail` é stderr cru do ssh — exibido
/// interpolado na frase traduzida da UI, nunca traduzido (regra de i18n).
class SshTunnelException implements Exception {
  const SshTunnelException(this.detail);
  final String detail;

  @override
  String toString() => 'SshTunnelException($detail)';
}
