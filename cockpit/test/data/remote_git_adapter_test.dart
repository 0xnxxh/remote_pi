import 'package:cockpit/app/cockpit/data/remote/remote_git_adapter.dart';
import 'package:cockpit/app/cockpit/domain/entities/git_file_status.dart';
import 'package:cockpit_core/cockpit_core.dart' as core;
import 'package:flutter_test/flutter_test.dart';

core.GitStatus status(String branch, List<(String, String, String)> files) =>
    core.GitStatus(
      branch: branch,
      files: [
        for (final (x, y, p) in files)
          core.GitFileStatus(staged: x, worktree: y, path: p),
      ],
    );

void main() {
  test('untracked → changed + files (untracked)', () {
    final info = remoteGitInfo(status('main', [('?', '?', 'new.txt')]));
    expect(info.branch, 'main');
    expect(info.changedFiles['new.txt'], GitFileStatus.untracked);
    expect(info.stagedFiles, isEmpty);
    expect(info.files['new.txt'], GitFileStatus.untracked);
  });

  test('staged add e worktree modify', () {
    final info = remoteGitInfo(
      status('dev', [('A', ' ', 'added.txt'), (' ', 'M', 'edited.txt')]),
    );
    expect(info.stagedFiles['added.txt'], GitFileStatus.staged);
    expect(info.changedFiles['edited.txt'], GitFileStatus.modified);
  });

  test('mesmo arquivo staged + nova edição no worktree (MM)', () {
    final info = remoteGitInfo(status('main', [('M', 'M', 'both.txt')]));
    expect(info.stagedFiles['both.txt'], GitFileStatus.staged);
    expect(info.changedFiles['both.txt'], GitFileStatus.modified);
    expect(info.files['both.txt'], GitFileStatus.modified); // strongest
  });

  test('conflito UU', () {
    final info = remoteGitInfo(status('main', [('U', 'U', 'c.txt')]));
    expect(info.files['c.txt'], GitFileStatus.conflict);
    expect(info.changedFiles['c.txt'], GitFileStatus.conflict);
  });

  test('deletado no worktree', () {
    final info = remoteGitInfo(status('main', [(' ', 'D', 'gone.txt')]));
    expect(info.changedFiles['gone.txt'], GitFileStatus.deleted);
  });
}
