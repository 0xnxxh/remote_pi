import 'dart:io';

import 'package:cockpit/app/core/utils/user_home.dart';
import 'package:file_picker/file_picker.dart';

/// Pasta onde as chaves SSH do usuário moram nesta máquina, ou a home quando
/// ela ainda não existe.
///
/// É o mesmo caminho nas três plataformas desktop (`%USERPROFILE%\.ssh` no
/// Windows é a pasta do OpenSSH nativo, a mesma que o `ssh.exe` lê). Abrir o
/// picker já lá poupa o usuário de navegar até uma pasta oculta — e `.ssh` é
/// oculta em todas elas.
String? sshKeyDirectory() {
  final home = userHome();
  if (home == null) return null;
  final ssh = Directory('$home/.ssh');
  return ssh.existsSync() ? ssh.path : home;
}

/// Abre o seletor de arquivo na pasta de chaves e devolve o caminho escolhido
/// (`null` se o usuário cancelar).
///
/// Sem filtro de extensão: chave privada não tem extensão nenhuma
/// (`id_ed25519`), e as que têm (`.pem`, `.key`) não seguem padrão. Filtrar
/// esconderia justamente o caso comum.
Future<String?> pickSshPrivateKey({String? dialogTitle}) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: dialogTitle,
    initialDirectory: sshKeyDirectory(),
    // A pasta tem `id_*.pub` ao lado das privadas; o usuário escolhe qual, e a
    // validação de "isso é mesmo uma chave" fica com o ssh, na conexão.
    type: FileType.any,
  );
  final path = result?.files.singleOrNull?.path;
  return (path == null || path.isEmpty) ? null : path;
}
