import 'package:cockpit/app/cockpit/domain/contracts/ssh_tunnel.dart';
import 'package:hive/hive.dart';

/// Host keys confiadas (TOFU) numa chave própria da Box de settings — reusa a
/// box, sem TypeAdapter (é só um mapa endpoint→fingerprint), no mesmo padrão
/// do `HiveDismissedUpdateStore`.
///
/// Deliberadamente **não** é o `known_hosts` do sistema: o `dartssh2` não lê
/// aquele arquivo (decisão C do plano 54), então manter o nosso é o que
/// permite detectar troca de host key.
class HiveSshHostKeyStore implements SshHostKeyStore {
  HiveSshHostKeyStore(this._box);

  final Box<dynamic> _box;

  static const String _key = 'ssh_known_host_keys';

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
  String? trusted(String endpoint) => _all()[endpoint];

  @override
  Future<void> trust(String endpoint, String fingerprint) =>
      _box.put(_key, _all()..[endpoint] = fingerprint);

  @override
  Future<void> forget(String endpoint) =>
      _box.put(_key, _all()..remove(endpoint));
}
