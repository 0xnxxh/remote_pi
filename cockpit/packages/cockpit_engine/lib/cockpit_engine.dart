/// Motor nativo do Cockpit Remote (Wave 0: domínio Terminais).
///
/// Este pacote toca `dart:ffi`/`dart:io` e SÓ pode ser importado pelo
/// `cockpit_server` (enforcement do guardrail mobile por pubspec).
library;

export 'src/pty/pty_dylib.dart';
export 'src/pty/native_terminal_service.dart';
export 'src/pty/scrollback_buffer.dart';
