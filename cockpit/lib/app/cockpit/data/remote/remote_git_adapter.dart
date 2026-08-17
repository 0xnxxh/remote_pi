import 'package:cockpit/app/cockpit/domain/entities/git_file_status.dart'
    as app;
import 'package:cockpit/app/cockpit/domain/entities/git_info.dart';
import 'package:cockpit_core/cockpit_core.dart' as core;

/// Converte o `GitStatus` do protocolo (porcelain XY) no `GitInfo` do app
/// (branch + mapas de status por caminho relativo), pra o painel de Source
/// Control funcionar igual ao git local (plano 58, source control remoto).
GitInfo remoteGitInfo(core.GitStatus status) {
  final files = <String, app.GitFileStatus>{};
  final stagedFiles = <String, app.GitFileStatus>{};
  final changedFiles = <String, app.GitFileStatus>{};
  final untrackedDirs = <String>{};

  for (final f in status.files) {
    final x = f.staged; // index
    final y = f.worktree; // working tree
    final path = f.path;

    if (_isConflict(x, y)) {
      files[path] = app.GitFileStatus.conflict;
      changedFiles[path] = app.GitFileStatus.conflict;
      continue;
    }
    if (x == '?' && y == '?') {
      // Untracked. O porcelain -z já lista pastas untracked colapsadas com
      // barra final; guardamos a raiz pra tingir os descendentes.
      final u = app.GitFileStatus.untracked;
      files[path] = u;
      changedFiles[path] = u;
      if (path.endsWith('/'))
        untrackedDirs.add(path.substring(0, path.length - 1));
      continue;
    }

    app.GitFileStatus? strongest;
    if (x != ' ' && x != '?') {
      final s = x == 'D' ? app.GitFileStatus.deleted : app.GitFileStatus.staged;
      stagedFiles[path] = s;
      strongest = app.GitFileStatus.strongest(strongest, s);
    }
    if (y != ' ' && y != '?') {
      final c = y == 'D'
          ? app.GitFileStatus.deleted
          : app.GitFileStatus.modified;
      changedFiles[path] = c;
      strongest = app.GitFileStatus.strongest(strongest, c);
    }
    if (strongest != null) files[path] = strongest;
  }

  return GitInfo(
    branch: status.branch,
    files: files,
    stagedFiles: stagedFiles,
    changedFiles: changedFiles,
    untrackedDirs: untrackedDirs,
  );
}

bool _isConflict(String x, String y) =>
    x == 'U' || y == 'U' || (x == 'A' && y == 'A') || (x == 'D' && y == 'D');
