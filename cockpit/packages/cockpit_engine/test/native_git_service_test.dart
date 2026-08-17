import 'dart:io';

import 'package:cockpit_core/cockpit_core.dart';
import 'package:cockpit_engine/cockpit_engine.dart';
import 'package:test/test.dart';

/// Exercita o parser do porcelain=v1 -z contra um repo git de verdade.
void main() {
  late Directory repo;
  const git = NativeGitService();

  setUp(() async {
    repo = await Directory.systemTemp.createTemp('git-svc-');
    Future<void> run(List<String> args) async {
      final r = await Process.run('git', ['-C', repo.path, ...args]);
      if (r.exitCode != 0) throw StateError('git ${args.first}: ${r.stderr}');
    }

    await run(['init', '-q']);
    await run(['config', 'user.email', 't@t']);
    await run(['config', 'user.name', 'T']);
  });

  tearDown(() => repo.delete(recursive: true));

  test('status: untracked → staged → committed', () async {
    File('${repo.path}/a.txt').writeAsStringSync('one\n');

    final untracked = await git.status(repo.path);
    expect(untracked.branch, isNotEmpty);
    expect(untracked.files.singleWhere((f) => f.path == 'a.txt').worktree, '?');

    await git.stage(repo.path, ['a.txt']);
    final staged = await git.status(repo.path);
    expect(staged.files.singleWhere((f) => f.path == 'a.txt').staged, 'A');

    await git.commit(repo.path, 'first');
    expect((await git.status(repo.path)).files, isEmpty);
  });

  test('diff mostra a mudança na worktree', () async {
    File('${repo.path}/a.txt').writeAsStringSync('one\n');
    await git.stage(repo.path, ['a.txt']);
    await git.commit(repo.path, 'first');
    File('${repo.path}/a.txt').writeAsStringSync('one\ntwo\n');

    final diff = await git.diff(repo.path, 'a.txt');
    expect(diff, contains('+two'));
  });

  test('repo inexistente vira GitException(notARepo)', () async {
    final notRepo = await Directory.systemTemp.createTemp('not-git-');
    addTearDown(() => notRepo.delete(recursive: true));
    expect(
      () => git.status(notRepo.path),
      throwsA(
        isA<GitException>().having(
          (e) => e.kind,
          'kind',
          GitErrorKind.notARepo,
        ),
      ),
    );
  });
}
