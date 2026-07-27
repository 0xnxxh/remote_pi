import 'dart:async';

import 'package:cockpit/app/cockpit/domain/contracts/db_connection_store.dart';
import 'package:cockpit/app/cockpit/domain/contracts/db_driver.dart';
import 'package:cockpit/app/cockpit/domain/contracts/nosql_runner.dart';
import 'package:cockpit/app/cockpit/domain/entities/db_connection.dart';
import 'package:cockpit/app/cockpit/domain/entities/db_result.dart';
import 'package:cockpit/app/cockpit/domain/services/db_query_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/ssh_fakes.dart';

/// A fila do serviço é serializada de propósito (o slot de conexão do anaki é
/// global por dylib), mas a **espera** precisa ter teto.
///
/// Sem isso, uma conexão lenta ou inalcançável fazia todas as queries do app —
/// de qualquer workspace e qualquer engine — esperarem sem explicação, e o
/// agente recebia "no response from app" em vez de um erro nomeado. Foi o que
/// aconteceu no E2E do plano 54 contra um Atlas fora de alcance.
void main() {
  late Completer<DbResult> stuck;
  late _HangingDriver driver;
  late DbQueryService service;

  final empty = DbResult(
    columns: const [],
    rows: const [],
    elapsed: Duration.zero,
  );

  setUp(() {
    stuck = Completer<DbResult>();
    driver = _HangingDriver(stuck);
    service =
        DbQueryService(
            _Store(),
            _NoSecrets(),
            _Registry(driver),
            _NoRunner(),
            FakeSshTunnel(),
            FakeSshKeyInspector(),
          )
          ..queueWait = const Duration(milliseconds: 80)
          ..operationCap = const Duration(milliseconds: 300);
  });

  Future<DbResult> call() => service.query(
    workspaceRoot: '/ws',
    workspaceId: 'w1',
    connName: 'db',
    sql: 'SELECT 1',
  );

  test('operação presa não trava as seguintes para sempre', () async {
    unawaited(call().catchError((Object _) => empty)); // fica presa
    await expectLater(
      call(),
      throwsA(isA<DbQueryException>().having((e) => e.kind, 'kind', 'busy')),
    );
  });

  test('quem desiste não executa — a serialização continua valendo', () async {
    unawaited(call().catchError((Object _) => empty));
    await call().catchError((Object _) => empty);
    // A primeira ocupa o slot; a segunda desistiu sem tocar no driver.
    expect(driver.calls, 1);
  });

  test('operação travada é abandonada e LIBERA a fila (auto-cura)', () async {
    // Sem isto, uma única operação presa deixava o serviço em `busy` para
    // sempre — só reiniciando o app. Foi o que aconteceu no E2E do plano 54.
    await expectLater(
      call(),
      throwsA(isA<DbQueryException>().having((e) => e.kind, 'kind', 'timeout')),
    );
    // A fila voltou: a próxima chega ao driver em vez de tomar `busy`.
    final second = call();
    stuck.complete(empty);
    await second;
    expect(driver.calls, 2);
  });

  test('fila anda normalmente quando a operação termina', () async {
    final first = call();
    stuck.complete(empty);
    await first;
    expect((await call()).rows, isEmpty);
    expect(driver.calls, 2);
  });
}

/// Driver que só completa quando o teste mandar.
class _HangingDriver implements DbDriver {
  _HangingDriver(this.gate);
  final Completer<DbResult> gate;
  int calls = 0;

  @override
  Future<DbResult> query(
    DbConnection conn,
    String sql, {
    required int limit,
    Duration timeout = const Duration(seconds: 30),
    String? password,
  }) {
    calls++;
    return gate.future;
  }

  @override
  Future<DbResult> execute(
    DbConnection conn,
    String sql, {
    Duration timeout = const Duration(seconds: 30),
    String? password,
  }) => gate.future;

  @override
  Future<DbResult> schema(
    DbConnection conn, {
    String? table,
    String? schema,
    Duration timeout = const Duration(seconds: 30),
    String? password,
  }) => gate.future;
}

class _Store implements DbConnectionStore {
  @override
  Future<List<DbConnection>> load(String workspaceRoot) async => [
    DbConnection.network(
      name: 'db',
      engine: DbEngine.postgres,
      host: 'h',
      database: 'd',
    ),
  ];
  @override
  Future<void> save(String root, List<DbConnection> connections) async {}
}

class _NoSecrets implements DbSecrets {
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
}

class _Registry implements DbDriverRegistry {
  _Registry(this.driver);
  final DbDriver driver;
  @override
  DbDriver? forEngine(DbEngine engine) => driver;
}

class _NoRunner implements NoSqlRunner {
  @override
  Future<Object?> redis(
    DbConnection conn,
    List<String> parts, {
    String? password,
  }) async => null;
  @override
  Future<List<Object?>> redisMany(
    DbConnection conn,
    List<List<String>> commands, {
    String? password,
  }) async => const [];
  @override
  Future<Object?> mongo(
    DbConnection conn,
    Map<String, dynamic> command, {
    String? password,
  }) async => null;
}
