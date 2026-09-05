#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
MANAGER="$ROOT_DIR/packages/agent-runtime/files/usr/sbin/agent-runtime"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

DATA_ROOT="$TMP_ROOT/data"
RUNTIME_ROOT="$DATA_ROOT/agent-runtime"
BASELINE_ROOT="$TMP_ROOT/baseline"
MOCK_BIN="$TMP_ROOT/bin"
mkdir -p "$RUNTIME_ROOT/generations/demo" "$BASELINE_ROOT" "$MOCK_BIN"
ln -s generations/demo "$RUNTIME_ROOT/current"

printf '%s\n' '#!/bin/sh' >"$MOCK_BIN/uci"
printf '%s\n' 'case "${3:-}" in' >>"$MOCK_BIN/uci"
printf '%s\n' "'agent_runtime.main.data_root') printf '%s\\n' '$DATA_ROOT' ;;" >>"$MOCK_BIN/uci"
printf '%s\n' "'agent_runtime.main.runtime_root') printf '%s\\n' '$RUNTIME_ROOT' ;;" >>"$MOCK_BIN/uci"
printf '%s\n' "'agent_runtime.main.baseline_root') printf '%s\\n' '$BASELINE_ROOT' ;;" >>"$MOCK_BIN/uci"
printf '%s\n' "'agent_runtime.main.public_key') printf '%s\\n' '$TMP_ROOT/missing.pub' ;;" >>"$MOCK_BIN/uci"
printf '%s\n' "'agent_runtime.main.release_url') exit 1 ;;" >>"$MOCK_BIN/uci"
printf '%s\n' '*) exit 1 ;; esac' >>"$MOCK_BIN/uci"
chmod 0755 "$MOCK_BIN/uci"

status="$(AGENT_RUNTIME_UCI_BIN="$MOCK_BIN/uci" sh "$MANAGER" status --json)"
printf '%s' "$status" | grep -Fq '"ok":true'
printf '%s' "$status" | grep -Fq '"generations":["demo"]'
printf '%s' "$status" | grep -Fq '"baseline_present":true'

listed="$(AGENT_RUNTIME_UCI_BIN="$MOCK_BIN/uci" sh "$MANAGER" list --json)"
printf '%s' "$listed" | grep -Fq '"active":"generations/demo"'

if AGENT_RUNTIME_UCI_BIN="$MOCK_BIN/uci" sh "$MANAGER" status --json unexpected >/dev/null 2>&1; then
	echo 'manager accepted an unbounded argument' >&2
	exit 1
fi

if AGENT_RUNTIME_UCI_BIN="$MOCK_BIN/uci" sh "$MANAGER" check --json >/dev/null 2>&1; then
	echo 'check must reject an unconfigured release URL' >&2
	exit 1
fi

echo 'agent runtime CLI fixture passed'
