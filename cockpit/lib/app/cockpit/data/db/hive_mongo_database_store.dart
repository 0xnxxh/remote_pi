import 'package:cockpit/app/cockpit/domain/contracts/mongo_database_store.dart';
import 'package:hive/hive.dart';

/// [MongoDatabaseStore] numa chave própria da box de settings — mesmo padrão
/// do `HiveSshHostKeyStore`: um mapa simples, sem TypeAdapter.
class HiveMongoDatabaseStore implements MongoDatabaseStore {
  HiveMongoDatabaseStore(this._box);

  final Box<dynamic> _box;

  static const String _key = 'mongo_selected_databases';

  /// `workspaceId::connName` — o `::` não aparece em UUID de workspace, e nome
  /// de conexão com `:` continua sem colidir (o split é pelo primeiro).
  static String entryKey(String workspaceId, String connName) =>
      '$workspaceId::$connName';

  Map<String, String> _all() {
    final raw = _box.get(_key);
    if (raw is! Map) return {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  @override
  String? selected(String workspaceId, String connName) =>
      _all()[entryKey(workspaceId, connName)];

  @override
  Future<void> select(
    String workspaceId,
    String connName,
    String database,
  ) => _box.put(_key, _all()..[entryKey(workspaceId, connName)] = database);
}
