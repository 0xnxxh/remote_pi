import 'package:cockpit/app/core/ui/themes/themes.dart';
import 'package:cockpit/app/core/ui/widgets/hover_tap.dart';
import 'package:cockpit/i18n/strings.g.dart';
import 'package:cockpit_core/cockpit_core.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Navega o filesystem REMOTO (via [FileService] do host) e devolve o caminho
/// da pasta escolhida — o "Add remote workspace" do plano 58: fixa uma pasta
/// específica do host, em vez de abrir sempre na HOME.
///
/// Recebe o serviço já conectado (o connector do host resolve a conexão SSH).
/// Começa em [initialPath] (HOME remota).
Future<String?> showRemoteFolderPicker(
  BuildContext context, {
  required FileService fileService,
  required String initialPath,
  required String hostName,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (context) => _RemoteFolderPicker(
      fileService: fileService,
      initialPath: initialPath,
      hostName: hostName,
    ),
  );
}

class _RemoteFolderPicker extends StatefulWidget {
  const _RemoteFolderPicker({
    required this.fileService,
    required this.initialPath,
    required this.hostName,
  });

  final FileService fileService;
  final String initialPath;
  final String hostName;

  @override
  State<_RemoteFolderPicker> createState() => _RemoteFolderPickerState();
}

class _RemoteFolderPickerState extends State<_RemoteFolderPicker> {
  late String _path = widget.initialPath;
  List<FileEntry>? _entries;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(_path);
  }

  Future<void> _load(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await widget.fileService.list(path);
      // Só pastas visíveis (o workspace é uma pasta).
      final dirs = all
          .where((e) => e.isDirectory && !e.name.startsWith('.'))
          .toList();
      if (!mounted) return;
      setState(() {
        _path = path;
        _entries = dirs;
        _loading = false;
      });
    } on FileException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.detail ?? e.kind.name;
        _loading = false;
      });
    }
  }

  String get _parent {
    final trimmed = _path.endsWith('/') && _path.length > 1
        ? _path.substring(0, _path.length - 1)
        : _path;
    final idx = trimmed.lastIndexOf('/');
    if (idx <= 0) return '/';
    return trimmed.substring(0, idx);
  }

  String _join(String dir, String name) =>
      dir.endsWith('/') ? '$dir$name' : '$dir/$name';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.t.cockpit.remoteHost;
    return AlertDialog(
      title: Text(
        tr.pickFolderTitle(host: widget.hostName),
        style: context.typo.title.copyWith(fontSize: 15, color: colors.text),
      ),
      content: SizedBox(
        width: 460,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caminho atual + subir um nível.
            Row(
              children: [
                IconButton.ghost(
                  density: ButtonDensity.compact,
                  onPressed: _path == '/' ? null : () => _load(_parent),
                  icon: const Icon(Icons.arrow_upward, size: 15),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _path,
                    overflow: TextOverflow.ellipsis,
                    style: context.typo.mono.copyWith(
                      fontSize: 12,
                      color: colors.text2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.panel,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: colors.border),
                ),
                child: _body(colors),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlineButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.cancel),
        ),
        PrimaryButton(
          // Abre nesta pasta.
          onPressed: _loading ? null : () => Navigator.of(context).pop(_path),
          child: Text(tr.openHere),
        ),
      ],
    );
  }

  Widget _body(AppColors colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: context.typo.label.copyWith(color: colors.error),
          ),
        ),
      );
    }
    final entries = _entries ?? const [];
    if (entries.isEmpty) {
      return Center(
        child: Text(
          context.t.cockpit.remoteHost.emptyFolder,
          style: context.typo.label.copyWith(color: colors.text2),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return HoverTap(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          onTap: () => _load(_join(_path, e.name)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 15, color: colors.text2),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    e.name,
                    overflow: TextOverflow.ellipsis,
                    style: context.typo.body.copyWith(
                      fontSize: 13,
                      color: colors.text,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 15, color: colors.text2),
              ],
            ),
          ),
        );
      },
    );
  }
}
