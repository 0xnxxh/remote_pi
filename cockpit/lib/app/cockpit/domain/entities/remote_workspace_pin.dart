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
    this.colorValue = defaultColor,
    this.imagePath,
  });

  /// Cor padrão do slot remoto (o teal do plano 58) quando o pin nunca foi
  /// customizado — mantém o visual anterior à personalização.
  static const int defaultColor = 0xFF0C7F87;

  /// Id estável do pin (`${hostId}:${path}` deterministicamente derivado).
  final String id;

  final String hostId;

  /// Caminho absoluto da pasta no filesystem do host.
  final String path;

  /// Nome de exibição (default = basename do [path]).
  final String name;

  /// Cor do slot (ARGB), personalizável nas Configurações do workspace remoto.
  final int colorValue;

  /// Imagem de fundo do avatar do slot (path local no cliente), ou `null`.
  final String? imagePath;

  RemoteWorkspacePin copyWith({
    String? name,
    int? colorValue,
    Object? imagePath = unsetImage,
  }) => RemoteWorkspacePin(
    id: id,
    hostId: hostId,
    path: path,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    imagePath: imagePath == unsetImage ? this.imagePath : imagePath as String?,
  );

  /// Sentinela do [copyWith]/updatePin: distingue "não mexer na imagem" de
  /// "limpar a imagem (null)".
  static const Object unsetImage = Object();

  static String idFor(String hostId, String path) => '$hostId::$path';

  factory RemoteWorkspacePin.fromJson(Map<String, Object?> json) =>
      RemoteWorkspacePin(
        id: json['id'] as String,
        hostId: json['host'] as String,
        path: json['path'] as String,
        name: json['name'] as String,
        colorValue: (json['color'] as num?)?.toInt() ?? defaultColor,
        imagePath: json['imagePath'] as String?,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'host': hostId,
    'path': path,
    'name': name,
    'color': colorValue,
    if (imagePath != null) 'imagePath': imagePath,
  };
}
