import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cockpit/app/cockpit/data/remote/remote_host_connector.dart';
import 'package:cockpit/app/cockpit/domain/contracts/terminal_gateway.dart';
import 'package:cockpit/app/core/domain/entities/terminal_profile.dart';
import 'package:cockpit/app/core/utils/spawn_directory.dart'
    show SpawnDirectory;
import 'package:cockpit_core/cockpit_core.dart';
import 'package:cockpit_remote/cockpit_remote.dart';

/// [TerminalGateway] de um workspace REMOTO: o PTY roda no `cockpit-server`
/// do host (via túnel SSH) e o emulador continua no cliente (plano 58,
/// Wave 2). Mesma forma do [SidecarTerminalGateway], com duas diferenças:
///
/// - a fonte do serviço é um [RemoteHostConnector] (SSH), não o sidecar local;
/// - **sem fallback in-process**: um workspace remoto sem host alcançável é um
///   erro (o stream fecha e a aba mostra o encerramento), nunca um shell
///   local silencioso na máquina errada.
class RemoteHostTerminalGateway implements TerminalGateway {
  RemoteHostTerminalGateway(this._connector);

  final RemoteHostConnector _connector;

  RemoteTerminalService? _service;
  String? _sessionId;
  StreamSubscription<PtyEvent>? _attachment;

  // Flow control por contador acumulado (mesma razão do gateway do sidecar).
  int _bytesDelivered = 0;
  int _bytesAcked = 0;

  final StreamController<List<int>> _output = StreamController<List<int>>();
  final List<void Function()> _queued = [];
  bool _ready = false;
  bool _killed = false;

  @override
  Stream<List<int>> get output => _output.stream;

  // Sem fallback de pasta: o path é do filesystem remoto, resolvido lá.
  @override
  SpawnDirectory? get spawnDirectory => null;

  @override
  void start({
    required String workingDirectory,
    required TerminalProfile profile,
    int rows = 25,
    int columns = 80,
    Map<String, String> extraEnv = const <String, String>{},
  }) {
    unawaited(_init(workingDirectory, profile, rows, columns, extraEnv));
  }

  Future<void> _init(
    String workingDirectory,
    TerminalProfile profile,
    int rows,
    int columns,
    Map<String, String> extraEnv,
  ) async {
    final RemoteTerminalService service;
    try {
      service = await _connector.ensure();
    } catch (_) {
      // Erro de conexão (SSH/bootstrap) — a UI já observa RemoteHostConnector
      // .phases pra mostrar loading/erro; aqui só encerra a aba.
      _closeOutput();
      return;
    }
    if (_killed) return;

    try {
      final info = await service.open(
        PtySpawnSpec(
          executable: profile.executable,
          arguments: profile.args,
          // Caminho é do filesystem REMOTO (vazio = HOME remota do servidor).
          workingDirectory: workingDirectory.isEmpty ? null : workingDirectory,
          environment: _terminalEnv(extraEnv),
          rows: rows,
          columns: columns,
          flowControlled: true,
        ),
      );
      if (_killed) {
        await service.kill(info.id);
        return;
      }
      _service = service;
      _sessionId = info.id;
      _attachment = service
          .attach(info.id)
          .listen(
            (event) {
              switch (event) {
                case PtyOutputEvent(:final chunk):
                  _bytesDelivered += chunk.bytes.length;
                  _output.add(chunk.bytes);
                case PtyExitEvent():
                  _closeOutput();
              }
            },
            onError: (Object _) => _closeOutput(),
            onDone: _closeOutput,
          );
      _flushQueue();
    } on TerminalException {
      _closeOutput();
    }
  }

  void _flushQueue() {
    _ready = true;
    for (final op in _queued) {
      op();
    }
    _queued.clear();
  }

  void _run(void Function() op) {
    if (_killed) return;
    if (_ready) {
      op();
    } else {
      _queued.add(op);
    }
  }

  void _closeOutput() {
    if (!_output.isClosed) _output.close();
  }

  @override
  void write(List<int> data) => _run(() {
    final id = _sessionId;
    if (id == null) return;
    unawaited(
      _service?.write(id, data is Uint8List ? data : Uint8List.fromList(data)),
    );
  });

  @override
  void resize(int rows, int columns) => _run(() {
    final id = _sessionId;
    if (id == null) return;
    unawaited(_service?.resize(id, rows, columns));
  });

  @override
  void acknowledgeOutput() {
    final id = _sessionId;
    final credit = _bytesDelivered - _bytesAcked;
    if (id == null || credit <= 0) return;
    _bytesAcked = _bytesDelivered;
    unawaited(_service?.ack(id, credit));
  }

  @override
  Future<void> kill() async {
    _killed = true;
    _queued.clear();
    await _attachment?.cancel();
    final id = _sessionId;
    if (id != null) {
      try {
        await _service?.kill(id);
      } on TerminalException {
        // sessão já encerrada.
      }
    }
    _closeOutput();
  }

  /// TERM/COLORTERM como nos outros gateways; o servidor remoto funde por cima
  /// do ambiente dele. Não herda `Platform.environment` local (é outra
  /// máquina) — o env do host vem do próprio servidor.
  Map<String, String> _terminalEnv(Map<String, String> extraEnv) => {
    if (!Platform.isWindows) 'TERM': 'xterm-256color',
    'COLORTERM': 'truecolor',
    ...extraEnv,
  };
}
