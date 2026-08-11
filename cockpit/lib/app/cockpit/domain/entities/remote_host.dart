/// Host remoto registrado no cliente (plano 58, decisão C): o cliente
/// persiste APENAS isto — id, nome de exibição e endpoint SSH. Realms,
/// workspaces e estado de sessão vivem no host dono.
class RemoteHost {
  const RemoteHost({
    required this.id,
    required this.name,
    required this.sshTarget,
  });

  /// UUID estável do registro (não muda se o endpoint mudar).
  final String id;

  /// Nome de exibição (badge no rail; a cor do host deriva dele por enquanto).
  final String name;

  /// Destino SSH como o usuário digitaria: `user@host`, alias do
  /// `~/.ssh/config`, `host:porta` não é suportado aqui — porta customizada
  /// vive no ssh config do usuário (decisão G: o binário `ssh` manda).
  final String sshTarget;

  factory RemoteHost.fromJson(Map<String, Object?> json) => RemoteHost(
    id: json['id'] as String,
    name: json['name'] as String,
    sshTarget: json['ssh'] as String,
  );

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'ssh': sshTarget};
}
