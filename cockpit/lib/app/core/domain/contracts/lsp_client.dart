import 'package:cockpit/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:cockpit/app/core/domain/exceptions/lsp_error.dart';
import 'package:cockpit/app/core/domain/result.dart';

/// Como ligar um language server: o comando (binário + args) e o `languageId`
/// LSP que o servidor atende. A tabela `lsp_launchers.dart` (Wave 2) produz uma
/// destas por linguagem; na Wave 0 é construída na mão para o Dart.
class LspServerSpec {
  const LspServerSpec({
    required this.languageId,
    required this.executable,
    this.args = const <String>[],
    this.capabilities = const <String, dynamic>{},
    this.initializationOptions = const <String, dynamic>{},
    this.serverRequestHandler,
    this.logStderr = true,
  });

  /// `languageId` do LSP (ex.: `dart`, `typescript`, `php`). Vai no `didOpen`.
  final String languageId;

  /// Caminho/nome do binário do servidor (resolvido no PATH antes de spawnar).
  final String executable;

  /// Argumentos fixos (ex.: `language-server`, `--stdio`).
  final List<String> args;

  /// Capabilities/initialization options adicionais para servidores que usam
  /// extensões públicas do LSP (como inline completion). Vazio usa o conjunto
  /// padrão do editor.
  final Map<String, dynamic> capabilities;
  final Map<String, dynamic> initializationOptions;

  /// Adapter opcional para requests servidor→cliente. Mantém particularidades
  /// de um servidor fora do transporte JSON-RPC genérico.
  final LspServerRequestHandler? serverRequestHandler;

  /// Alguns servidores podem incluir dados sensíveis nos logs. Adapters podem
  /// desativar o encaminhamento sem afetar o transporte.
  final bool logStderr;
}

class LspNotification {
  const LspNotification(this.method, this.params);
  final String method;
  final Object? params;
}

abstract class LspServerRequestHandler {
  Future<Object?> handle(String method, Object? params);
}

/// Cliente de **um** language server (um processo, uma raiz de projeto). Fala
/// JSON-RPC 2.0 com framing `Content-Length` por stdin/stdout. O pool
/// (`LspServerPool`) é quem cria/reusa/descarta instâncias por
/// `(linguagem, raiz)` — este contrato é a peça de baixo nível.
abstract class LspClient {
  /// Diagnostics publicados pelo servidor (`textDocument/publishDiagnostics`),
  /// um batch por documento a cada publicação. Broadcast.
  Stream<LspDiagnosticsBatch> get diagnostics;

  /// Todas as notificações servidor→cliente, inclusive extensões específicas.
  Stream<LspNotification> get notifications =>
      const Stream<LspNotification>.empty();

  /// Exit codes do processo. Permite que adapters traduzam queda inesperada.
  Stream<int> get exitCodes => const Stream<int>.empty();

  bool get isRunning;

  /// Raiz absoluta do projeto que este servidor atende.
  String get rootPath;

  /// Spawna o processo e faz o handshake (`initialize` → `initialized`).
  Future<Result<void, LspError>> start();

  /// `textDocument/didOpen`. [path] é absoluto; vira `file://` URI internamente.
  Future<void> didOpen({required String path, required String text});

  /// Variante usada por adapters que abrem documentos virtuais com um
  /// `languageId` diferente do servidor. O default preserva compatibilidade
  /// com clientes fake/alternativos que só implementam [didOpen].
  Future<void> didOpenWithLanguage({
    required String path,
    required String text,
    required String languageId,
  }) => didOpen(path: path, text: text);

  /// `textDocument/didChange` (full sync). [version] cresce a cada edição.
  Future<void> didChange({
    required String path,
    required String text,
    required int version,
  });

  /// `textDocument/didClose`.
  Future<void> didClose({required String path});

  /// Request JSON-RPC genérico (ex.: `textDocument/formatting` na Wave 3).
  /// Lança/retorna falha em timeout ou erro do servidor.
  Future<Result<Object?, LspError>> request(
    String method,
    Map<String, dynamic> params,
  );

  /// Request com timeout customizado. O default mantém implementações antigas
  /// compatíveis; o transporte oficial sobrescreve para também remover o
  /// request do mapa interno ao expirar.
  Future<Result<Object?, LspError>> requestWithTimeout(
    String method,
    Map<String, dynamic> params,
    Duration timeout,
  ) => request(method, params).timeout(timeout);

  /// Notificação genérica cliente→servidor. Default no-op para transports que
  /// suportam apenas o subconjunto histórico usado pelo editor.
  void notify(String method, Map<String, dynamic> params) {}

  /// Cancela todos os requests pendentes com `$/cancelRequest`.
  void cancelPendingRequests() {}

  /// Encerra graciosamente (`shutdown`/`exit` → close stdin → SIGTERM → SIGKILL).
  Future<void> kill();

  /// Rede de segurança síncrona (shutdown do app): mata o processo sem órfão.
  void dispose();
}

/// Fábrica de [LspClient] — interface nomeada (não `Function()`) para seguir a
/// regra de injeção `.new` do projeto (o parser do auto_injector quebra em
/// `X Function()`). O pool injeta esta factory e cria um cliente por raiz.
abstract class LspClientFactory {
  LspClient create({required LspServerSpec spec, required String rootPath});
}
