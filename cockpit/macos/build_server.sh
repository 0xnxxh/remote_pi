#!/bin/bash
# Compila o `cockpit-server` (plano 58: Dart AOT headless, packages/cockpit_server)
# + a dylib do PTY e empacota em Resources do .app, assinados.
#
# ATENÇÃO — arquitetura: AOT do Dart NÃO sobrevive ao lipo (mesma razão que
# levou a CLI pra Rust). O servidor embarca em FATIA ÚNICA (a do host que
# buildou); a dylib C vai universal. Num Mac Intel com app buildado em Apple
# Silicon, o binário não roda e o app cai no PTY in-process sozinho (fallback
# do SidecarTerminalGateway) — pendência registrada no plano 58 (fatia x64
# via runner Intel no CI, arquivos por arch escolhidos em runtime).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"   # cockpit/

resolve_dart() {
  if [ -n "${FLUTTER_ROOT:-}" ] && [ -x "$FLUTTER_ROOT/bin/dart" ]; then
    echo "$FLUTTER_ROOT/bin/dart"; return
  fi
  if command -v dart >/dev/null 2>&1; then command -v dart; return; fi
  echo "[build_server] erro: 'dart' não encontrado" >&2
  exit 1
}
DART="$(resolve_dart)"

: "${BUILT_PRODUCTS_DIR:?precisa rodar pelo Xcode (BUILT_PRODUCTS_DIR ausente)}"
: "${PRODUCT_NAME:?PRODUCT_NAME ausente}"
RES="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Resources"
mkdir -p "$RES"

# Dylib do PTY: universal (C compila as duas fatias num comando).
SRC="$ROOT/plugins/cockpit_pty/src"
DYLIB="$RES/libcockpit_pty.dylib"
cc -dynamiclib -O2 -DDART_SHARED_LIB -arch arm64 -arch x86_64 \
  -o "$DYLIB" "$SRC/cockpit_pty.c" -I"$SRC" -lpthread
echo "[build_server] dylib $(/usr/bin/lipo -archs "$DYLIB")"

# Servidor: AOT da arquitetura do host.
( cd "$ROOT/packages/cockpit_server" && "$DART" pub get >/dev/null )
DEST="$RES/cockpit-server"
"$DART" compile exe "$ROOT/packages/cockpit_server/bin/cockpit_server.dart" \
  -o "$DEST" >/dev/null
chmod +x "$DEST"

# Prova executável (padrão do build_cli: estrutura não basta): sobe num
# socket de probe e mata. NUNCA rodar sem --socket/kill — o binário não tem
# --help e ficaria escutando no socket default como órfão.
PROBE="$(mktemp -d)/probe.sock"
COCKPIT_PTY_DYLIB="$DYLIB" "$DEST" --socket "$PROBE" >/dev/null 2>&1 &
PROBE_PID=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -S "$PROBE" ] && break; sleep 0.3; done
if [ ! -S "$PROBE" ]; then
  kill "$PROBE_PID" 2>/dev/null || true
  echo "[build_server] erro: o binário gerado não sobe" >&2
  exit 1
fi
kill "$PROBE_PID" 2>/dev/null || true
rm -f "$PROBE"

IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY:-}"
if [ -z "$IDENTITY" ] || [ "$IDENTITY" = "-" ]; then
  echo "[build_server] codesign ad-hoc (dev)"
  codesign --force -s - "$DYLIB" "$DEST"
else
  echo "[build_server] codesign ($IDENTITY) + hardened runtime"
  codesign --force --options runtime \
    --entitlements "$ROOT/macos/cockpit_hook.entitlements" \
    -s "$IDENTITY" "$DYLIB" "$DEST"
fi
echo "[build_server] bundle OK -> $DEST ($(/usr/bin/lipo -archs "$DEST"))"
