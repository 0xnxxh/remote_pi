@TestOn('mac-os')
library;

import 'dart:convert';
import 'dart:io';

import 'package:cockpit/app/cockpit/data/terminal/sidecar/sidecar_terminal_connector.dart';
import 'package:cockpit/app/cockpit/data/terminal/sidecar/sidecar_terminal_gateway_factory.dart';
import 'package:cockpit/app/core/domain/entities/terminal_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integração da Wave 1 (plano 58): o gateway do app servido pelo sidecar
/// real. Requer `./tool/build-sidecar.sh` (build/wave0/); sem os artefatos o
/// teste é pulado — o fallback in-process é coberto pelo uso normal do app.
void main() {
  final binary = File('build/wave0/cockpit-server');

  test(
    'terminal via sidecar: eco, ack e kill',
    () async {
      if (!binary.existsSync()) {
        markTestSkipped(
          'build/wave0/cockpit-server ausente; rode tool/build-sidecar.sh',
        );
        return;
      }

      final connector = SidecarTerminalConnector();
      addTearDown(connector.dispose);

      final gateway = SidecarTerminalGatewayFactory(connector).create();
      final collected = StringBuffer();
      var chunks = 0;

      gateway.start(
        workingDirectory: Directory.systemTemp.path,
        profile: const TerminalProfile(
          id: 'login-shell',
          label: 'zsh',
          executable: '/bin/zsh',
          args: ['-f'],
        ),
        extraEnv: const {'WAVE1_MARKER': 'sidecar'},
      );
      final sub = gateway.output.listen((data) {
        chunks++;
        collected.write(utf8.decode(data, allowMalformed: true));
        gateway.acknowledgeOutput(); // papel do coalescer: crédito por chunk.
      });

      // write antes do backend pronto exercita a fila de operações.
      gateway.write(utf8.encode('echo wave1-\$WAVE1_MARKER-\$((40+2))\n'));

      await _until(() => collected.toString().contains('wave1-sidecar-42'));
      expect(chunks, greaterThan(0));

      gateway.resize(40, 120);
      gateway.write(utf8.encode('stty size\n'));
      await _until(() => collected.toString().contains('40 120'));

      await gateway.kill();
      await sub.cancel();
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}

Future<void> _until(bool Function() test) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (!test()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condição não satisfeita a tempo');
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}
