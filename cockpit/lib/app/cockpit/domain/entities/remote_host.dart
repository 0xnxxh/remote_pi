/// Modo de autenticação SSH escolhido para o host (plano 60, Wave C).
enum RemoteHostAuth {
  /// Chave do dispositivo (default): desktop usa `~/.ssh`/agent; mobile usa a
  /// chave ed25519 do Keychain.
  key,

  /// Senha, guardada no Keychain (nunca no JSON). Mobile passa direto ao
  /// dartssh2; desktop injeta via `SSH_ASKPASS`.
  password,
}

/// Host remoto registrado no cliente (plano 58, decisão C): o cliente
/// persiste APENAS isto — id, nome de exibição e endpoint SSH. Realms,
/// workspaces e estado de sessão vivem no host dono. A senha (quando
/// [auth] == password) mora no Keychain, não aqui.
class RemoteHost {
  const RemoteHost({
    required this.id,
    required this.name,
    required this.sshTarget,
    this.port = 22,
    this.auth = RemoteHostAuth.key,
  });

  /// UUID estável do registro (não muda se o endpoint mudar).
  final String id;

  /// Nome de exibição (badge no rail; a cor do host deriva dele por enquanto).
  final String name;

  /// Destino SSH como `user@host` (sem porta — a porta vive em [port]). O
  /// cadastro coleta usuário e host separados e combina aqui.
  final String sshTarget;

  /// Porta SSH (default 22). Desktop passa `-p`; mobile usa no endpoint.
  final int port;

  /// Modo de autenticação. Ver [RemoteHostAuth].
  final RemoteHostAuth auth;

  /// `user` do `user@host` (vazio se não houver `@`).
  String get user {
    final at = sshTarget.indexOf('@');
    return at <= 0 ? '' : sshTarget.substring(0, at);
  }

  /// `host` do `user@host` (o todo se não houver `@`).
  String get host {
    final at = sshTarget.indexOf('@');
    return at < 0 ? sshTarget : sshTarget.substring(at + 1);
  }

  RemoteHost copyWith({
    String? name,
    String? sshTarget,
    int? port,
    RemoteHostAuth? auth,
  }) => RemoteHost(
    id: id,
    name: name ?? this.name,
    sshTarget: sshTarget ?? this.sshTarget,
    port: port ?? this.port,
    auth: auth ?? this.auth,
  );

  factory RemoteHost.fromJson(Map<String, Object?> json) {
    // Retrocompatível: registros antigos só têm `ssh` (user@host[:porta]).
    // Extrai a porta embutida no legado, se houver.
    final raw = json['ssh'] as String? ?? '';
    var target = raw;
    var port = (json['port'] as num?)?.toInt() ?? 22;
    final at = raw.lastIndexOf('@');
    final colon = raw.lastIndexOf(':');
    if (json['port'] == null && colon > at) {
      final parsed = int.tryParse(raw.substring(colon + 1));
      if (parsed != null) {
        port = parsed;
        target = raw.substring(0, colon);
      }
    }
    return RemoteHost(
      id: json['id'] as String,
      name: json['name'] as String,
      sshTarget: target,
      port: port,
      auth: (json['auth'] as String?) == 'password'
          ? RemoteHostAuth.password
          : RemoteHostAuth.key,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'ssh': sshTarget,
    'port': port,
    'auth': auth == RemoteHostAuth.password ? 'password' : 'key',
  };
}
