import 'package:cockpit/app/cockpit/domain/entities/remote_host.dart';

/// Registro de hosts remotos do cliente (plano 58, decisão C): a ÚNICA coisa
/// que o cliente persiste sobre remoto — id, nome, endpoint SSH.
abstract class RemoteHostsStore {
  List<RemoteHost> hosts();
  Future<void> save(RemoteHost host);
  Future<void> remove(String id);
}
