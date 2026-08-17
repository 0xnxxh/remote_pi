import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda a senha SSH de um host no **Keychain/Keystore** (via
/// `flutter_secure_storage`), keyed por `host.id` — nunca no JSON de hosts
/// (plano 60, Wave C, decisão A). Funciona nos dois lados: mobile passa a senha
/// ao dartssh2; desktop injeta via `SSH_ASKPASS`.
class RemoteHostPasswordStore {
  RemoteHostPasswordStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _prefix = 'cockpit.ssh.password.';

  String _key(String hostId) => '$_prefix$hostId';

  /// Senha do host, ou `null` se não houver.
  Future<String?> read(String hostId) => _storage.read(key: _key(hostId));

  /// Grava (ou remove, se [password] for `null`/vazia) a senha do host.
  Future<void> write(String hostId, String? password) async {
    if (password == null || password.isEmpty) {
      await _storage.delete(key: _key(hostId));
    } else {
      await _storage.write(key: _key(hostId), value: password);
    }
  }

  /// Apaga a senha do host (ao remover o host, ou ao trocar pra auth por chave).
  Future<void> remove(String hostId) => _storage.delete(key: _key(hostId));
}
