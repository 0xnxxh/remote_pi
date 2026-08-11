/// Protocolo Cockpit Remote v1 (Wave 0: handshake + domínio Terminais).
///
/// Transporte: JSONL (um objeto JSON por linha, UTF-8) sobre socket local
/// (UDS) ou túnel SSH. Bytes de PTY viajam em base64. Documentação completa
/// em `docs/remote-protocol.md`.
library;

export 'src/messages.dart';
export 'src/codec.dart';
