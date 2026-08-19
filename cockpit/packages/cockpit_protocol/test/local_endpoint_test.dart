import 'dart:io';

import 'package:cockpit_protocol/cockpit_protocol.dart';
import 'package:test/test.dart';

/// O transporte local precisa funcionar nas duas formas: socket UNIX no POSIX e
/// TCP loopback + token no Windows, onde o `dart:io` não tem UDS — foi o bind
/// estourando lá que deixava todo terminal do Windows no fallback in-process.
void main() {
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cockpit-endpoint');
    path = '${dir.path}/cockpit-server.sock';
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('anuncia, aceita conexão e devolve os mesmos bytes', () async {
    final endpoint = await LocalEndpoint.bind(path);
    addTearDown(endpoint.close);
    endpoint.listener.listen((socket) {
      socket.add([1, 2, 3]);
      socket.close();
    });

    expect(LocalEndpoint.announcedAt(path), isTrue);

    final client = await LocalEndpoint.connect(path);
    expect(await client.socket.first, [1, 2, 3]);
    // O token existe exatamente onde o transporte é TCP compartilhado.
    expect(client.token, LocalEndpoint.usesTcp ? isNotEmpty : isNull);
    expect(client.token, endpoint.token);
  });

  test('close remove o anúncio (senão a próxima descoberta se engana)',
      () async {
    final endpoint = await LocalEndpoint.bind(path);
    await endpoint.close();

    expect(LocalEndpoint.announcedAt(path), isFalse);
  });

  test('bind por cima de um anúncio órfão funciona', () async {
    File(path).writeAsStringSync('lixo do ciclo anterior');

    final endpoint = await LocalEndpoint.bind(path);
    addTearDown(endpoint.close);
    endpoint.listener.listen((s) => s.close());

    final client = await LocalEndpoint.connect(path);
    addTearDown(client.socket.destroy);
    expect(client.socket, isNotNull);
  });

  test('connect sem servidor algum falha', () async {
    await expectLater(LocalEndpoint.connect(path), throwsA(anything));
  });

  test('Hello leva token e flag local no wire', () {
    const hello = Hello(
      version: protocolVersion,
      client: 'cockpit-gui',
      token: 'abc',
      local: true,
    );
    final json = hello.toJson();
    expect(json['tok'], 'abc');
    expect(json['loc'], true);

    final back = Hello.fromJson(json);
    expect(back.token, 'abc');
    expect(back.local, isTrue);

    // Compatibilidade: cliente antigo não manda os campos novos.
    final old = Hello.fromJson({
      't': 'hello',
      'v': protocolVersion,
      'client': 'legacy',
    });
    expect(old.token, isNull);
    expect(old.local, isFalse);
  });
}
