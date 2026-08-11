import 'dart:io';

import 'package:cockpit_core/cockpit_core.dart';

/// [GitService] rodando o binário `git` do host servidor (plano 58, Wave 3).
/// Motor é o git do sistema; nosso é o parser/orquestração — mesmo modelo do
/// `data/filesystem/git_*` do app, agora do lado do servidor.
class NativeGitService implements GitService {
  const NativeGitService();

  @override
  Future<GitStatus> status(String repoPath) async {
    // --porcelain=v1 -b: 1ª linha "## branch...", demais "XY path".
    final result = await _git(repoPath, [
      'status',
      '--porcelain=v1',
      '-b',
      '-z',
    ]);
    final parts = result.split('\x00');
    var branch = '';
    final files = <GitFileStatus>[];
    for (final entry in parts) {
      if (entry.isEmpty) continue;
      if (entry.startsWith('## ')) {
        // "## main...origin/main [ahead 1]" → "main"
        branch = entry.substring(3).split('...').first.split(' ').first.trim();
        continue;
      }
      if (entry.length < 3) continue;
      files.add(
        GitFileStatus(
          staged: entry[0],
          worktree: entry[1],
          path: entry.substring(3),
        ),
      );
    }
    return GitStatus(branch: branch, files: files);
  }

  @override
  Future<String> diff(String repoPath, String file, {bool staged = false}) =>
      _git(repoPath, ['diff', if (staged) '--cached', '--', file]);

  @override
  Future<void> stage(String repoPath, List<String> files) async {
    await _git(repoPath, ['add', '--', ...files]);
  }

  @override
  Future<void> unstage(String repoPath, List<String> files) async {
    await _git(repoPath, ['restore', '--staged', '--', ...files]);
  }

  @override
  Future<void> commit(String repoPath, String message) async {
    await _git(repoPath, ['commit', '-m', message]);
  }

  Future<String> _git(String repoPath, List<String> args) async {
    final ProcessResult result;
    try {
      result = await Process.run(
        'git',
        ['-C', repoPath, ...args],
        stdoutEncoding: SystemEncoding(),
        stderrEncoding: SystemEncoding(),
      );
    } on ProcessException catch (e) {
      throw GitException(GitErrorKind.command, e.message);
    }
    if (result.exitCode != 0) {
      final stderr = (result.stderr as String).trim();
      final kind = stderr.contains('not a git repository')
          ? GitErrorKind.notARepo
          : GitErrorKind.command;
      throw GitException(kind, stderr);
    }
    return result.stdout as String;
  }
}
