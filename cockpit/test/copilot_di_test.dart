import 'package:cockpit/app/core/core_module.dart';
import 'package:cockpit/app/core/data/terminal/terminal_profile_resolver_impl.dart';
import 'package:cockpit/app/core/env.dart';
import 'package:cockpit/app/core/ui/copilot_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) =>
      MaterialApp.router(routerConfig: ModularApp.routerConfigOf(context));
}

void main() {
  testWidgets('CopilotController root instance is observable from routes', (
    tester,
  ) async {
    final core = buildCoreModule(
      config: const PiSpawnConfig(executable: 'pi'),
      terminalProfiles: TerminalProfileResolverImpl(),
    );
    final feature = createModule(
      path: '/',
      register: (c) => c.route(
        '/',
        child: (context, state) =>
            Text(context.watch<CopilotController>().status.message),
      ),
    );
    final app = createModule(
      register: (c) => c
        ..module(core)
        ..module(feature),
    );

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ModularApp(
        module: app,
        navigatorKey: navigatorKey,
        provide: (services) => services.addChangeNotifier<CopilotController>(
          () => inject<CopilotController>(),
        ),
        child: const _Root(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GitHub Copilot is not connected.'), findsOneWidget);
    // O contexto da key é o que o bootstrap usa para dialogs pós-inicialização;
    // diferente do contexto acima do ModularApp, ele inclui um Navigator.
    expect(() => Navigator.of(navigatorKey.currentContext!), returnsNormally);
  });
}
