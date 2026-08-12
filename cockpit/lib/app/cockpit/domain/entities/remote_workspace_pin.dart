/// Um workspace remoto fixado pelo cliente (plano 58): uma PASTA de um host.
/// Vários pins podem apontar para o mesmo host (pastas distintas = workspaces
/// distintos), espelhando o modelo de workspace local (que é uma pasta).
///
/// O cliente persiste só o ponteiro `(hostId, path)` + nome de exibição; o
/// estado de trabalho (git, worktrees, sessões) vive no host dono.
class RemoteWorkspacePin {
  const RemoteWorkspacePin({
    required this.id,
    required this.hostId,
    required this.path,
    required this.name,
  });

  /// Id estável do pin (`${hostId}:${path}` deterministicamente derivado).
  final String id;

  final String hostId;

  /// Caminho absoluto da pasta no filesystem do host.
  final String path;

  /// Nome de exibição (default = basename do [path]).
  final String name;

  static String idFor(String hostId, String path) => '$hostId::$path';

  factory RemoteWorkspacePin.fromJson(Map<String, Object?> json) =>
      RemoteWorkspacePin(
        id: json['id'] as String,
        hostId: json['host'] as String,
        path: json['path'] as String,
        name: json['name'] as String,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'host': hostId,
    'path': path,
    'name': name,
  };
}
