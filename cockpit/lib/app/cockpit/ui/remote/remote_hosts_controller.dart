import 'dart:io';

import 'package:cockpit/app/cockpit/data/remote/remote_host_connector.dart';
import 'package:cockpit/app/cockpit/data/remote/remote_host_terminal_gateway.dart';
import 'package:cockpit/app/cockpit/domain/contracts/remote_hosts_store.dart';
import 'package:cockpit/app/cockpit/domain/contracts/terminal_gateway.dart';
import 'package:cockpit/app/cockpit/domain/entities/remote_host.dart';
import 'package:cockpit/app/core/utils/user_home.dart';
import 'package:flutter/foundation.dart';

/// Estado app-scoped dos hosts remotos (plano 58, Wave 2/fecho): dono do
/// registro persistido + um [RemoteHostConnector] por host (uma conexão SSH
/// por host, reusada por todos os terminais daquele workspace).
///
/// A UI (rail) observa este controller pra listar os pins e o badge de estado;
/// o [CockpitViewModel] pede o gateway de terminal de um host por aqui.
class RemoteHostsController extends ChangeNotifier {
  RemoteHostsController(this._store);

  final RemoteHostsStore _store;
  final Map<String, RemoteHostConnector> _connectors = {};

  List<RemoteHost> get hosts => _store.hosts();

  RemoteHostConnector _connectorFor(RemoteHost host) => _connectors.putIfAbsent(
    host.id,
    () => RemoteHostConnector(
      host,
      localServerBinaryResolver: _resolveLocalServerBinary,
    ),
  );

  /// Fase de conexão atual de um host (pro badge do rail). `idle` se nunca
  /// conectou.
  RemoteHostPhase phaseOf(String hostId) =>
      _connectors[hostId]?.phase ?? RemoteHostPhase.idle;

  Stream<RemoteHostPhase>? phasesOf(String hostId) =>
      _connectors[hostId]?.phases;

  /// Gateway de terminal ligado ao [host] (via SSH). Reusa o connector do
  /// host; a UI é notificada das fases pra pintar loading/erro.
  TerminalGateway terminalGateway(RemoteHost host) {
    final connector = _connectorFor(host);
    connector.phases.listen((_) => notifyListeners());
    return RemoteHostTerminalGateway(connector);
  }

  Future<void> addHost({
    required String name,
    required String sshTarget,
  }) async {
    final host = RemoteHost(id: _nextId(), name: name, sshTarget: sshTarget);
    await _store.save(host);
    notifyListeners();
  }

  Future<void> removeHost(String id) async {
    await _connectors.remove(id)?.dispose();
    await _store.remove(id);
    notifyListeners();
  }

  // id determinístico simples (Date.now/Random não estão disponíveis em alguns
  // caminhos; aqui é UI, mas mantemos previsível): maior sufixo + 1.
  String _nextId() {
    final existing = hosts
        .map((h) => int.tryParse(h.id) ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return '${existing + 1}';
  }

  String? _resolveLocalServerBinary() {
    final candidates = <String?>[
      Platform.environment['COCKPIT_SERVER_BIN'],
      if (Platform.isMacOS)
        '${File(Platform.resolvedExecutable).parent.parent.path}'
            '/Resources/cockpit-server',
      () {
        final home = userHome();
        return home == null ? null : '$home/.cockpit/bin/cockpit-server';
      }(),
      '${Directory.current.path}/build/wave0/cockpit-server',
    ];
    for (final candidate in candidates) {
      if (candidate != null && File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  @override
  void dispose() {
    for (final connector in _connectors.values) {
      connector.dispose();
    }
    _connectors.clear();
    super.dispose();
  }
}
