#!/usr/bin/env bash
# Tests for pagedrop and install. A stub curl on PATH stands in for the network.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export STUB_OUT="$WORK/out"
mkdir -p "$STUB_OUT"
chmod +x "$ROOT/test/bin/curl" "$ROOT/pagedrop"

# PATH without jq, to exercise the python3 and grep fallbacks
NOJQ="$WORK/nojq"
mkdir -p "$NOJQ"
for tool in bash env cat grep cut python3 uname mkdir chmod dirname mktemp rm; do
  ln -s "$(command -v "$tool")" "$NOJQ/$tool"
done

fails=0
check() { # name, exit status of the condition
  if [ "$2" -eq 0 ]; then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi
}

HTML="$WORK/a.html"
echo '<h1>hi</h1>' > "$HTML"

run() { # PATH, FAKE, args...; sets OUT, ERR, CODE
  local p="$1" fake="$2"; shift 2
  OUT=$(PATH="$p" FAKE="$fake" "$ROOT/pagedrop" "$@" 2> "$WORK/err"); CODE=$?
  ERR=$(cat "$WORK/err")
}
WITHJQ="$ROOT/test/bin:$PATH"
WITHOUTJQ="$ROOT/test/bin:$NOJQ"

run "$WITHJQ" ok "$HTML"
[ "$CODE" = 0 ] && [ "$OUT" = "https://pagedrop.io/x/abc" ]; check "prints url (jq)" $?

run "$WITHJQ" off "$HTML"
[ "$CODE" != 0 ] && [[ "$ERR" == *"could not reach pagedrop.io"* ]]; check "offline: clear error, non-zero" $?

run "$WITHJQ" junk "$HTML"
[ "$CODE" != 0 ] && [[ "$ERR" == *"oops not json"* ]]; check "non-JSON response: raw body printed" $?

run "$WITHOUTJQ" spaced "$HTML"
[ "$CODE" = 0 ] && [ "$OUT" = "https://pagedrop.io/x/abc" ]; check "no-jq grep fallback handles space after colon" $?

BIG="$WORK/big.html"
head -c 300000 /dev/zero | tr '\0' 'a' > "$BIG"
for mode in jq python; do
  if [ "$mode" = jq ]; then P="$WITHJQ"; else P="$WITHOUTJQ"; fi
  rm -f "$STUB_OUT/maxarg" "$STUB_OUT/payload"
  run "$P" ok "$BIG"
  maxarg=$(cat "$STUB_OUT/maxarg" 2>/dev/null || echo 0)
  [ "$CODE" = 0 ] && [ "$maxarg" -lt 100000 ] && [ "$(wc -c < "$STUB_OUT/payload")" -gt 300000 ]
  check "large file ($mode): not passed as one argument" $?
done

for mode in jq python; do
  if [ "$mode" = jq ]; then P="$ROOT/test/fail-bin:$WITHJQ"; else P="$ROOT/test/fail-bin:$WITHOUTJQ"; fi
  rm -f "$STUB_OUT/called"
  run "$P" ok "$HTML"
  [ "$CODE" != 0 ] && [[ "$ERR" == *"could not build upload payload"* ]] && [ ! -e "$STUB_OUT/called" ]
  check "payload build failure ($mode): error, curl never called" $?
done

HOME_DIR="$WORK/home"
install_with_shell() { # SHELL value
  rm -rf "$HOME_DIR"; mkdir -p "$HOME_DIR"; : > "$HOME_DIR/.zshrc"; : > "$HOME_DIR/.bashrc"
  HOME="$HOME_DIR" SHELL="$1" PATH="$ROOT/test/bin:/usr/bin:/bin" bash "$ROOT/install" > "$WORK/install.out" 2>&1
}
install_with_shell /bin/zsh
grep -q 'pagedrop-cli install' "$HOME_DIR/.zshrc" && ! grep -q 'pagedrop-cli install' "$HOME_DIR/.bashrc"
check "installer: SHELL=zsh writes .zshrc" $?
install_with_shell /bin/bash
grep -q 'pagedrop-cli install' "$HOME_DIR/.bashrc" && ! grep -q 'pagedrop-cli install' "$HOME_DIR/.zshrc"
check "installer: SHELL=bash writes .bashrc" $?

WGET_PATH="$WORK/wgetonly"
mkdir -p "$WGET_PATH"
for tool in bash env uname mkdir chmod dirname basename grep; do
  ln -s "$(command -v "$tool")" "$WGET_PATH/$tool"
done
rm -rf "$HOME_DIR"; mkdir -p "$HOME_DIR"
HOME="$HOME_DIR" SHELL=/bin/bash PATH="$ROOT/test/wget-bin:$WGET_PATH" bash "$ROOT/install" > "$WORK/install.out" 2>&1
[ -x "$HOME_DIR/.local/bin/pagedrop" ]; check "installer: wget branch downloads the script" $?

[ "$fails" = 0 ] || { echo "$fails failed"; exit 1; }
echo "all passed"
