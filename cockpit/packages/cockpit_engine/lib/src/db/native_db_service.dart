import 'dart:async';
import 'dart:isolate';

import 'package:anaki_mssql/anaki_mssql.dart';
import 'package:anaki_mysql/anaki_mysql.dart';
import 'package:anaki_orm/anaki_orm.dart';
import 'package:anaki_postgres/anaki_postgres.dart';
import 'package:anaki_sqlite/anaki_sqlite.dart';
import 'package:cockpit_core/cockpit_core.dart';

/// Executa queries SQL no host via anaki (plano 58, Wave 4). Roda cada query
/// num Isolate (a FFI bloqueia a thread), constrói o driver do engine lá
/// dentro, abre, executa e fecha — mesmo modelo do `AnakiDbDriver` do app.
class NativeDbService implements DbService {
  const NativeDbService({this.timeout = const Duration(seconds: 30)});

  final Duration timeout;

  @override
  Future<Map<String, Object?>> query(
    RemoteDbConnDescriptor conn,
    String sql, {
    int limit = 200,
    bool dml = false,
  }) async {
    try {
      return await Isolate.run(
        () => _runInIsolate(conn, sql, limit, dml),
      ).timeout(timeout);
    } on DbServiceException {
      rethrow;
    } on TimeoutException {
      throw DbServiceException(
        DbErrorKind.timeout,
        'Query exceeded ${timeout.inSeconds}s',
      );
    }
  }

  static Future<Map<String, Object?>> _runInIsolate(
    RemoteDbConnDescriptor conn,
    String sql,
    int limit,
    bool dml,
  ) async {
    final watch = Stopwatch()..start();
    final driver = _buildDriver(conn);
    try {
      await driver.rawOpen();
    } on AnakiException catch (e) {
      throw DbServiceException(DbErrorKind.connectionFailed, '$e');
    }
    try {
      if (dml) {
        final affected = await driver.rawExecute(sql, null);
        return {
          'columns': const [],
          'rows': const [],
          'rowCount': 0,
          'truncated': false,
          'elapsedMs': watch.elapsedMilliseconds,
          'affectedRows': affected,
        };
      }
      final rows = await driver.rawQuery(sql, null);
      return _toResultJson(rows, limit, watch);
    } on ConnectionException catch (e) {
      throw DbServiceException(DbErrorKind.connectionFailed, '$e');
    } on AnakiException catch (e) {
      throw DbServiceException(DbErrorKind.queryFailed, '$e');
    } finally {
      try {
        await driver.rawClose();
      } on AnakiException {
        // fechar falhou após o resultado — nada útil a fazer.
      }
    }
  }

  static Map<String, Object?> _toResultJson(
    List<Map<String, dynamic>> rows,
    int limit,
    Stopwatch watch,
  ) {
    if (rows.isEmpty) {
      return {
        'columns': const [],
        'rows': const [],
        'rowCount': 0,
        'truncated': false,
        'elapsedMs': watch.elapsedMilliseconds,
      };
    }
    final columns = rows.first.keys.toList();
    final truncated = rows.length > limit;
    final data = [
      for (final row in truncated ? rows.take(limit) : rows)
        [for (final c in columns) _cell(row[c])],
    ];
    return {
      'columns': [
        for (final c in columns) {'name': c, 'type': ''},
      ],
      'rows': data,
      'rowCount': data.length,
      'truncated': truncated,
      'elapsedMs': watch.elapsedMilliseconds,
    };
  }

  /// Normaliza a célula pro JSON do fio (mesma política do DbResult do app:
  /// DateTime→ISO, blob→marcador de tamanho).
  static Object? _cell(Object? v) => switch (v) {
    null || int() || double() || bool() || String() => v,
    DateTime() => v.toIso8601String(),
    List<int>() => {'blob': v.length},
    _ => v.toString(),
  };

  static AnakiDriver _buildDriver(RemoteDbConnDescriptor conn) {
    final params = conn.url.isEmpty
        ? const <String, String>{}
        : Uri.parse(conn.url).queryParameters;
    switch (conn.engine) {
      case 'sqlite':
        return SqliteDriver(conn.sqlitePath);
      case 'postgres':
        return PostgresDriver(
          host: conn.host,
          port: conn.port ?? 5432,
          username: conn.user,
          password: conn.password ?? '',
          database: conn.database,
          sslMode: params['sslmode'],
        );
      case 'mysql':
        return MysqlDriver(
          host: conn.host,
          port: conn.port ?? 3306,
          username: conn.user,
          password: conn.password ?? '',
          database: conn.database,
          sslMode: params['ssl-mode']?.toLowerCase(),
        );
      case 'mssql':
        return MssqlDriver(
          host: conn.host,
          port: conn.port ?? 1433,
          username: conn.user,
          password: conn.password ?? '',
          database: conn.database,
          trustCert: params['trustcert'] == 'true',
          encrypt: switch (params['encrypt']) {
            'true' => true,
            'false' => false,
            _ => null,
          },
        );
      default:
        throw DbServiceException(
          DbErrorKind.unsupportedEngine,
          '${conn.engine} is not a supported SQL engine',
        );
    }
  }
}
