// cockpit-server (plano 58, Wave 0) — binário headless, sem Flutter.
//
// Composição via auto_injector puro (mesmo motor do flutter_modular v7),
// seguindo as convenções do app: registro por tear-off `.new` quando o grafo
// resolve sozinho.
import 'dart:async';
import 'dart:io';

import 'package:auto_injector/auto_injector.dart';
import 'package:cockpit_core/cockpit_core.dart';
import 'package:cockpit_engine/cockpit_engine.dart';
import 'package:cockpit_server/cockpit_server.dart';

Future<void> main(List<String> args) async {
  final socketPath =
      _argValue(args, '--socket') ??
      '${Directory.systemTemp.path}/cockpit-server-${pid}.sock';

  final injector = AutoInjector()
    ..addLazySingleton<TerminalService>(NativeTerminalService.new)
    ..addLazySingleton<RemoteServer>(RemoteServer.new)
    ..commit();

  final server = injector.get<RemoteServer>();
  await server.bind(socketPath);

  // Saída em inglês por decisão (CLI interna não se traduz).
  stdout.writeln('cockpit-server listening on $socketPath');

  ProcessSignal.sigint.watch().listen((_) async {
    await server.close();
    exit(0);
  });
  ProcessSignal.sigterm.watch().listen((_) async {
    await server.close();
    exit(0);
  });
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}
