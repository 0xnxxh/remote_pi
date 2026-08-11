// Bindings FFI mínimos do cockpit_pty para Dart puro (Wave 0, plano 58).
//
// Escritos à mão (a API são 6 funções + init) para não depender do pacote
// Flutter `cockpit_pty` — o layout do struct segue `src/cockpit_pty.h`.
import 'dart:ffi';

final class PtyOptionsNative extends Struct {
  @Int32()
  external int rows;

  @Int32()
  external int cols;

  external Pointer<Char> executable;

  /// Array NULL-terminated; convenção execvp: argv[0] = executable.
  external Pointer<Pointer<Char>> arguments;

  /// Array NULL-terminated de "CHAVE=valor".
  external Pointer<Pointer<Char>> environment;

  external Pointer<Char> workingDirectory;

  @Int64()
  external int stdoutPort;

  @Int64()
  external int exitPort;

  @Bool()
  external bool ackRead;
}

typedef _InitC = IntPtr Function(Pointer<Void>);
typedef _InitDart = int Function(Pointer<Void>);
typedef _CreateC = Pointer<Void> Function(Pointer<PtyOptionsNative>);
typedef _WriteC = Void Function(Pointer<Void>, Pointer<Char>, Int32);
typedef _WriteDart = void Function(Pointer<Void>, Pointer<Char>, int);
typedef _ResizeC = Int32 Function(Pointer<Void>, Int32, Int32);
typedef _ResizeDart = int Function(Pointer<Void>, int, int);
typedef _GetPidC = Int32 Function(Pointer<Void>);
typedef _GetPidDart = int Function(Pointer<Void>);
typedef _ErrorC = Pointer<Char> Function();

class PtyBindings {
  PtyBindings(DynamicLibrary lib)
    : initializeApiDL = lib.lookupFunction<_InitC, _InitDart>(
        'Dart_InitializeApiDL',
      ),
      create = lib.lookupFunction<_CreateC, _CreateC>('pty_create'),
      write = lib.lookupFunction<_WriteC, _WriteDart>('pty_write'),
      resize = lib.lookupFunction<_ResizeC, _ResizeDart>('pty_resize'),
      getPid = lib.lookupFunction<_GetPidC, _GetPidDart>('pty_getpid'),
      error = lib.lookupFunction<_ErrorC, _ErrorC>('pty_error');

  final _InitDart initializeApiDL;
  final _CreateC create;
  final _WriteDart write;
  final _ResizeDart resize;
  final _GetPidDart getPid;
  final _ErrorC error;
}
