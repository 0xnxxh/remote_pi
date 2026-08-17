import 'package:cockpit/app/cockpit/domain/contracts/git_command_runner.dart';
import 'package:cockpit/app/cockpit/domain/contracts/git_status_reader.dart';
import 'package:cockpit/app/cockpit/domain/entities/git_info.dart';
import 'package:cockpit/app/cockpit/ui/viewmodels/git_controller.dart';
import 'package:cockpit/app/core/core_module.dart';
import 'package:cockpit/app/core/data/terminal/terminal_profile_resolver_impl.dart';
import 'package:cockpit/app/core/env.dart';
import 'package:cockpit/app/core/ui/window_activity_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'core instance resolves into route-scoped GitController with identity',
    (tester) async {
      final activity = WindowActivityController();
      addTearDown(activity.dispose);
      final core = buildCoreModule(
        config: const PiSpawnConfig(executable: 'pi'),
        terminalProfiles: TerminalProfileResolverImpl(),
        windowActivity: activity,
      );
      final feature = createModule(
        path: '/',
        register: (c) => c
          ..addInstance<GitStatusReader>(_FakeGitStatusReader())
          ..addInstance<GitCommandRunner>(_FakeGitCommandRunner())
          ..route(
            '/',
            provide: (s) =>
                s..addChangeNotifier<GitController>(GitController.new),
            child: (context, state) => Builder(
              builder: (context) {
                final git = context.watch<GitController>();
                final injected = inject<WindowActivityController>();
                return Text(
                  'git:${git.revision};same:${identical(injected, activity)}',
                );
              },
            ),
          ),
      );
      final app = createModule(
        register: (c) => c
          ..module(core)
          ..module(feature),
      );
      final boot = bootstrapModule(app);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: modularRouterConfig(
            boot.routes,
            injector: boot.injector,
            manager: boot.manager,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('git:0;same:true'), findsOneWidget);
      expect(
        identical(boot.injector.get<WindowActivityController>(), activity),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeGitStatusReader implements GitStatusReader {
  @override
  Future<GitInfo?> read(String path) async => null;
}

class _FakeGitCommandRunner implements GitCommandRunner {
  Never _unused() => throw UnimplementedError();

  @override
  GitMergeOutcome mergeIntoParent(
    String parentPath,
    String worktreePath,
    String worktreeBranch,
  ) => _unused();

  @override
  GitRun run(String repoPath, List<String> args) => _unused();

  @override
  GitRun syncPullPush(String repoPath) => _unused();
}
