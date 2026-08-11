#!/usr/bin/env bash
# Compila o cockpit-server + dylib do PTY para o fluxo de DEV (plano 58,
# Wave 1). O app (flutter run a partir de cockpit/) encontra o resultado em
# build/wave0/; sem esses artefatos o app cai no PTY in-process sozinho.
#
# Uso:  ./tool/build-sidecar.sh [--install]
#   --install  copia também para ~/.cockpit/bin (onde o app instalado procura)
set -euo pipefail

cd "$(dirname "$0")/.."
./tool/wave0/build_pty_dylib.sh

( cd packages/cockpit_server && dart pub get >/dev/null )
dart compile exe packages/cockpit_server/bin/cockpit_server.dart \
  -o build/wave0/cockpit-server
echo "ok: build/wave0/cockpit-server"

if [ "${1:-}" = "--install" ]; then
  mkdir -p "$HOME/.cockpit/bin"
  cp build/wave0/cockpit-server "$HOME/.cockpit/bin/cockpit-server"
  cp build/wave0/libcockpit_pty."$([ "$(uname -s)" = Darwin ] && echo dylib || echo so)" \
    "$HOME/.cockpit/bin/" 2>/dev/null || true
  echo "ok: instalado em ~/.cockpit/bin"
fi
