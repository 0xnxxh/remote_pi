#!/usr/bin/env bash
# Funde a fatia x86_64 do cockpit-server (plano 58) no bundle arm64 do host,
# deixando bin/ + lib/ UNIVERSAIS. Necessário porque `dart build cli` não
# cross-compila: cada arquitetura sai de um build próprio (o CI monta o x64
# num runner Intel). Sem isso, Mac Intel cai no fallback in-process.
#
# Uso:
#   tool/lipo-server-bundle.sh <target-bundle> <x64-bundle> [sign-identity]
#
#   <target-bundle>  bundle arm64 a virar universal, in place (ex.: o do .app
#                    em Resources/cockpit-server-bundle)
#   <x64-bundle>     bundle x86_64 vindo do runner Intel (bin/ + lib/)
#   [sign-identity]  opcional; se dado, reassina cada Mach-O fundido (o lipo
#                    invalida a assinatura anterior). Sem ela, o chamador assina.
#
# Idempotente por natureza do lipo: um arquivo que já tem as duas fatias e um
# x64 idêntico refunde pro mesmo resultado. Se a contraparte x64 faltar, aborta
# alto (universal incompleto é pior que arm64-only silencioso).
set -euo pipefail

TARGET="${1:?target bundle ausente}"
X64="${2:?x64 bundle ausente}"
IDENTITY="${3:-}"

[ -d "$TARGET" ] || { echo "[lipo] target não existe: $TARGET" >&2; exit 1; }
[ -d "$X64" ] || { echo "[lipo] x64 bundle não existe: $X64" >&2; exit 1; }

merge_one() {
  local rel="$1"
  local dst="$TARGET/$rel"
  local src="$X64/$rel"
  [ -f "$dst" ] || return 0 # arquivo só existe num layout: nada a fundir.
  if [ ! -f "$src" ]; then
    echo "::error::fatia x64 faltando para $rel (Mac Intel ficaria quebrado)" >&2
    exit 1
  fi
  # Já universal? lipo -create rejeitaria fatias duplicadas; extrai a arm64.
  local armslice
  armslice="$(mktemp)"
  if lipo -archs "$dst" | grep -q x86_64; then
    lipo "$dst" -thin arm64 -output "$armslice"
  else
    cp "$dst" "$armslice"
  fi
  local x64slice="$src"
  if lipo -archs "$src" | grep -q arm64; then
    x64slice="$(mktemp)"
    lipo "$src" -thin x86_64 -output "$x64slice"
  fi
  lipo -create "$armslice" "$x64slice" -output "$dst"
  chmod +x "$dst"
  if [ -n "$IDENTITY" ]; then
    codesign --force --options runtime --timestamp -s "$IDENTITY" "$dst"
  fi
  echo "[lipo] universal: $rel ($(lipo -archs "$dst"))"
}

# O exe e todas as dylibs. libcockpit_pty já sai universal do build_server
# (cc -arch arm64 -arch x86_64), mas passar por aqui é inócuo.
for f in "$TARGET"/bin/*; do
  [ -f "$f" ] && merge_one "bin/$(basename "$f")"
done
for f in "$TARGET"/lib/*.dylib; do
  [ -f "$f" ] && merge_one "lib/$(basename "$f")"
done

echo "[lipo] bundle universal pronto: $TARGET"
