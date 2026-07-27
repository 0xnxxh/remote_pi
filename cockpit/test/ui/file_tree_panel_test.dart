import 'dart:async';

import 'package:cockpit/app/cockpit/domain/entities/file_node.dart';
import 'package:cockpit/app/cockpit/domain/entities/git_file_status.dart';
import 'package:cockpit/app/cockpit/ui/widgets/file_tree_panel.dart';
import 'package:cockpit/app/core/domain/result.dart';
import 'package:cockpit/app/core/ui/themes/themes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  group('FileTreePanel selection', () {
    testWidgets(
      'clicking on a file triggers onSelectFile and onTapFile callbacks',
      (tester) async {
        String? selectedFile;
        String? tappedFile;

        await tester.pumpWidget(
          ShadcnApp(
            theme: buildTheme(brightness: Brightness.dark),
            home: Scaffold(
              child: FileTreePanel(
                rootPath: '/workspace',
                revision: 1,
                listChildren: (path) async {
                  if (path == '/workspace') {
                    return const [
                      FileNode(
                        name: 'file1.txt',
                        path: '/workspace/file1.txt',
                        isDirectory: false,
                      ),
                    ];
                  }
                  return const [];
                },
                gitStatusOf: (path) => null,
                onOpenFile: (path) {},
                onTapFile: (path) {
                  tappedFile = path;
                },
                onSelectFile: (path) {
                  selectedFile = path;
                },
                onOpenDiff: (path) {},
                isGitRepo: false,
                changedPaths: const [],
                onOpenWith: (path) {},
                onCreateInFolder: (sub, terminal) {},
                onCreate: (parentDir, name, isFolder) async =>
                    const Success(null),
                onRename: (path, newName) async => const Success(null),
                onDelete: (path) async => const Success(null),
                onMove: (path, targetDir) async => const Success(null),
                onCopy: (_) {},
                onCut: (_) {},
                onPaste: (_) async => const Success(null),
                canPaste: false,
              ),
            ),
          ),
        );

        // Wait for lazy-loading to complete and rebuild
        await tester.pumpAndSettle();

        // Find the file node in the tree
        final fileFinder = find.text('file1.txt');
        expect(fileFinder, findsOneWidget);

        // Click on the file
        await tester.tap(fileFinder);
        await tester.pumpAndSettle();

        // Verify that callbacks were invoked with the correct file path
        expect(selectedFile, '/workspace/file1.txt');
        expect(tappedFile, '/workspace/file1.txt');
      },
    );

    testWidgets('source control alternates between list and tree views', (
      tester,
    ) async {
      const changedPath = '/workspace/lib/app/main.dart';

      await tester.pumpWidget(
        ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: Scaffold(
            child: FileTreePanel(
              rootPath: '/workspace',
              revision: 1,
              listChildren: (_) async => const [],
              gitStatusOf: (path) =>
                  path == changedPath ? GitFileStatus.modified : null,
              onOpenFile: (_) {},
              onOpenDiff: (_) {},
              isGitRepo: true,
              changedPaths: const [changedPath],
              onOpenWith: (_) {},
              onCreateInFolder: (_, _) {},
              onCreate: (_, _, _) async => const Success(null),
              onRename: (_, _) async => const Success(null),
              onDelete: (_) async => const Success(null),
              onMove: (_, _) async => const Success(null),
              onCopy: (_) {},
              onCut: (_) {},
              onPaste: (_) async => const Success(null),
              canPaste: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('source-control-tab')));
      await tester.pumpAndSettle();

      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('lib/app'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('source-control-view-toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('lib/app'), findsNothing);
      expect(find.text('lib'), findsOneWidget);
      expect(find.text('app'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('source-control-file:$changedPath')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('source-control-view-toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('lib/app'), findsOneWidget);
    });

    testWidgets('folder expansion survives stage and unstage', (tester) async {
      const changedPath = '/workspace/lib/app/main.dart';
      var staged = false;

      await tester.pumpWidget(
        ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: Scaffold(
            child: StatefulBuilder(
              builder: (context, setHostState) => FileTreePanel(
                rootPath: '/workspace',
                revision: 1,
                listChildren: (_) async => const [],
                gitStatusOf: (_) =>
                    staged ? GitFileStatus.staged : GitFileStatus.modified,
                onOpenFile: (_) {},
                onOpenDiff: (_) {},
                isGitRepo: true,
                changedPaths: const [changedPath],
                stagedPaths: staged ? const [changedPath] : const [],
                unstagedPaths: staged ? const [] : const [changedPath],
                onStageFiles: (_) async {
                  setHostState(() => staged = true);
                  return null;
                },
                onUnstageFiles: (_) async {
                  setHostState(() => staged = false);
                  return null;
                },
                onOpenWith: (_) {},
                onCreateInFolder: (_, _) {},
                onCreate: (_, _, _) async => const Success(null),
                onRename: (_, _) async => const Success(null),
                onDelete: (_) async => const Success(null),
                onMove: (_, _) async => const Success(null),
                onCopy: (_) {},
                onCut: (_) {},
                onPaste: (_) async => const Success(null),
                canPaste: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('source-control-tab')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('source-control-view-toggle')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('lib'));
      await tester.pumpAndSettle();
      expect(find.text('app'), findsNothing);

      final folder = find.byKey(
        const ValueKey('source-control-folder:/workspace/lib'),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(folder));
      await mouse.moveTo(tester.getCenter(folder));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('toggle-stage-folder:/workspace/lib')),
      );
      await tester.pumpAndSettle();
      expect(find.text('STAGED CHANGES (1)'), findsOneWidget);
      expect(find.text('app'), findsNothing);

      await mouse.moveTo(Offset.zero);
      await mouse.moveTo(tester.getCenter(folder));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('toggle-stage-folder:/workspace/lib')),
      );
      await tester.pumpAndSettle();
      expect(find.text('CHANGES (1)'), findsOneWidget);
      expect(find.text('app'), findsNothing);
    });

    testWidgets(
      'staged Copilot action follows amend picker and shows loading',
      (tester) async {
        const changedPath = '/workspace/lib/app/main.dart';
        final generation = Completer<Result<String, String>>();

        await tester.pumpWidget(
          ShadcnApp(
            theme: buildTheme(brightness: Brightness.dark),
            home: Scaffold(
              child: FileTreePanel(
                rootPath: '/workspace',
                revision: 1,
                listChildren: (_) async => const [],
                gitStatusOf: (_) => GitFileStatus.staged,
                onOpenFile: (_) {},
                onOpenDiff: (_) {},
                isGitRepo: true,
                changedPaths: const [changedPath],
                stagedPaths: const [changedPath],
                onGenerateStagedCommitMessage: () => generation.future,
                onOpenWith: (_) {},
                onCreateInFolder: (_, _) {},
                onCreate: (_, _, _) async => const Success(null),
                onRename: (_, _) async => const Success(null),
                onDelete: (_) async => const Success(null),
                onMove: (_, _) async => const Success(null),
                onCopy: (_) {},
                onCut: (_) {},
                onPaste: (_) async => const Success(null),
                canPaste: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('source-control-tab')));
        await tester.pumpAndSettle();

        final picker = find.byKey(const ValueKey('amend-commit-picker'));
        final generate = find.byKey(
          const ValueKey('generate-staged-commit-message'),
        );
        final toolbar = tester.widget<Row>(
          find.byKey(const ValueKey('commit-composer-toolbar')),
        );
        expect(toolbar.mainAxisAlignment, MainAxisAlignment.spaceBetween);
        expect(
          tester.getTopRight(picker).dx,
          lessThan(tester.getTopLeft(generate).dx),
        );
        expect(find.text('Generate with Copilot'), findsNothing);
        expect(
          find.descendant(
            of: generate,
            matching: find.byIcon(Icons.auto_awesome),
          ),
          findsOneWidget,
        );

        await tester.tap(generate);
        await tester.pump();

        expect(
          find.descendant(
            of: generate,
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );

        generation.complete(const Success('feat: generated message'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: generate,
            matching: find.byIcon(Icons.auto_awesome),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
