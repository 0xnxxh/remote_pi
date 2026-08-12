import 'package:cockpit_core/cockpit_core.dart';

import 'remote_connection.dart';

/// [DbService] via protocolo (plano 58, Wave 4): manda o descritor de conexão
/// + SQL ao servidor, que executa no host e devolve o resultado já-JSON.
class RemoteDbService implements DbService {
  RemoteDbService(this._connection);

  final RemoteConnection _connection;

  @override
  Future<Map<String, Object?>> query(
    RemoteDbConnDescriptor conn,
    String sql, {
    int limit = 200,
    bool dml = false,
  }) async {
    try {
      final data = await _connection.call('db.query', {
        'conn': conn.toJson(),
        'sql': sql,
        'limit': limit,
        'dml': dml,
      });
      return (data as Map).cast<String, Object?>();
    } on RemoteRpcException catch (e) {
      throw DbServiceException(
        DbErrorKind.values.asNameMap()[e.code] ?? DbErrorKind.queryFailed,
        e.detail,
      );
    }
  }
}
