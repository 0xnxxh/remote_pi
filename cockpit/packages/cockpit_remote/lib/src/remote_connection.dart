import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cockpit_core/cockpit_core.dart';
import 'package:cockpit_protocol/cockpit_protocol.dart';

/// Erro de uma chamada RPC (fs.*/git.*). `code` é estável; `detail` é texto
/// cru (stderr do git, errno) — traduzido só na borda da UI.
class RemoteRpcException implements Exception {
  const RemoteRpcException(this.code, [this.detail]);
  final String code;
  final String? detail;

  @override
  String toString() => 'RemoteRpcException($code: $detail)';
}

/// Conexão de cliente com um cockpit-server (Wave 0: socket UDS local;
/// o túnel SSH da Wave 2 entrega exatamente o mesmo socket).
class RemoteConnection {
  RemoteConnection._(this._socket, this.serverVersion, this._messages);

  static const _codec = RemoteMessageCodec();

  final Socket _socket;

  /// Versão reportada pelo servidor no handshake.
  final String serverVersion;

  final StreamController<RemoteMessage> _messages;
  bool _open = true;

  /// Stream broadcast de todas as mensagens do servidor.
  Stream<RemoteMessage> get messages => _messages.stream;

  /// Falso após queda do socket ou [close].
  bool get isOpen => _open;

  /// Conecta, faz o handshake e devolve a conexão pronta.
  static Future<RemoteConnection> connect(
    String socketPath, {
    String clientName = 'cockpit',
  }) async {
    final socket = await Socket.connect(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    );
    // Erros de escrita chegam async pelo done do socket (ex.: EPIPE quando um
    // forward SSH aceita localmente mas o lado remoto recusa) — sem este
    // guard, derrubam o processo por fora de qualquer try/catch.
    unawaited(socket.done.catchError((Object _) {}));

    // Uma única subscription do socket, alimentando um broadcast; o
    // handshake é apenas a primeira mensagem desse stream.
    final messages = StreamController<RemoteMessage>.broadcast();
    _codec
        .decodeStream(socket)
        .listen(
          messages.add,
          onError: (Object e) {
            messages.addError(
              TerminalException(TerminalErrorKind.transport, '$e'),
            );
            messages.close();
          },
          onDone: messages.close,
        );

    final firstReply = messages.stream.first;
    socket.add(
      utf8.encode(
        _codec.encode(Hello(version: protocolVersion, client: clientName)),
      ),
    );

    final ack = await firstReply.timeout(const Duration(seconds: 10));
    if (ack is RemoteError) {
      socket.destroy();
      throw TerminalException(TerminalErrorKind.protocol, ack.code);
    }
    if (ack is! HelloAck) {
      socket.destroy();
      throw const TerminalException(
        TerminalErrorKind.protocol,
        'unexpected handshake reply',
      );
    }
    final connection = RemoteConnection._(socket, ack.server, messages);
    unawaited(messages.done.then((_) => connection._open = false));
    return connection;
  }

  void send(RemoteMessage message) {
    if (!_open) return;
    _socket.add(utf8.encode(_codec.encode(message)));
  }

  int _nextRid = 0;

  /// Chamada RPC request/response (domínios fs.*/git.* da Wave 3). Correlaciona
  /// pela `rid`; devolve o `data` em sucesso, lança [RemoteRpcException] no
  /// `ok:false`. Concorrência livre: N chamadas in-flight, cada uma espera a
  /// sua rid.
  Future<Object?> call(
    String method, [
    Map<String, Object?> params = const {},
  ]) {
    if (!_open) {
      throw const RemoteRpcException('transport', 'connection closed');
    }
    final rid = _nextRid++;
    final completer = Completer<Object?>();
    late StreamSubscription<RemoteMessage> sub;
    sub = messages.listen(
      (m) {
        if (m is RpcResponse && m.rid == rid) {
          sub.cancel();
          if (m.ok) {
            completer.complete(m.data);
          } else {
            completer.completeError(
              RemoteRpcException(m.code ?? 'error', m.detail),
            );
          }
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            const RemoteRpcException('transport', 'connection closed'),
          );
        }
      },
    );
    send(RpcRequest(rid: rid, method: method, params: params));
    return completer.future;
  }

  Future<void> close() async {
    _open = false;
    _socket.destroy();
  }
}
