#!/usr/bin/env bash
# Compila o cockpit-server (com os native assets do anaki) + a dylib do PTY
# para o fluxo de DEV (plano 58). Usa `dart build cli` (NÃO `dart compile
# exe`, que não suporta build hooks) → bundle `bin/` + `lib/`. O app encontra
# o resultado em build/server-bundle/bin/cockpit-server; sem ele o app cai no
# PTY in-process sozinho.
#
# Uso:  ./tool/build-sidecar.sh
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
OUT="$ROOT/build/server-bundle"

./tool/wave0/build_pty_dylib.sh

( cd packages/cockpit_server && dart pub get >/dev/null )
rm -rf "$OUT"
( cd packages/cockpit_server && dart build cli -o "$OUT" >/dev/null )

# `dart build cli` gera <out>/bundle/{bin,lib}. Normaliza para <out>/{bin,lib}
# e batiza o exe como `cockpit-server` (o pacote é `cockpit_server`).
if [ -d "$OUT/bundle" ]; then
  mv "$OUT"/bundle/* "$OUT"/ && rmdir "$OUT/bundle"
fi
if [ -f "$OUT/bin/cockpit_server" ]; then
  mv "$OUT/bin/cockpit_server" "$OUT/bin/cockpit-server"
fi

# A dylib do PTY vai pra lib/ (o exe resolve @executable_path/../lib).
ext="$([ "$(uname -s)" = Darwin ] && echo dylib || echo so)"
cp "build/wave0/libcockpit_pty.$ext" "$OUT/lib/" 2>/dev/null || true

echo "ok: $OUT/bin/cockpit-server (+ lib/: $(ls "$OUT/lib" | tr '\n' ' '))"
