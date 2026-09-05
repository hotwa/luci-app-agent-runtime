#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CORE="$ROOT_DIR/packages/agent-runtime"
LUCI="$ROOT_DIR/packages/luci-app-agent-runtime"

for file in \
	"$CORE/Makefile" \
	"$CORE/files/etc/config/agent-runtime" \
	"$CORE/files/etc/init.d/agent-runtime" \
	"$CORE/files/usr/sbin/agent-runtime" \
	"$LUCI/Makefile" \
	"$LUCI/htdocs/luci-static/resources/view/agent-runtime/overview.js" \
	"$LUCI/htdocs/luci-static/resources/view/agent-runtime/settings.js" \
	"$LUCI/root/usr/libexec/agent-runtime-rpcd-job" \
	"$LUCI/root/usr/share/luci/menu.d/luci-app-agent-runtime.json" \
	"$LUCI/root/usr/share/rpcd/acl.d/luci-app-agent-runtime.json" \
	"$LUCI/root/usr/share/rpcd/ucode/agent-runtime.uc"; do
	[ -f "$file" ] || { echo "missing $file" >&2; exit 1; }
done

sh -n "$CORE/files/usr/sbin/agent-runtime"
sh -n "$CORE/files/etc/init.d/agent-runtime"
sh -n "$LUCI/root/usr/libexec/agent-runtime-rpcd-job"

grep -Fq 'PKGARCH:=all' "$CORE/Makefile"
grep -Fq 'LUCI_PKGARCH:=all' "$LUCI/Makefile"
grep -Fq '+agent-runtime' "$LUCI/Makefile"
grep -Fq 'admin/system/agent-runtime' "$LUCI/root/usr/share/luci/menu.d/luci-app-agent-runtime.json"
grep -Fq 'admin/system/agent-runtime/settings' "$LUCI/root/usr/share/luci/menu.d/luci-app-agent-runtime.json"

# The root-level rpcd interface is intentionally a closed operation set.
for action in status list check verify reconcile job_status; do
	grep -Fq "$action" "$LUCI/root/usr/share/rpcd/ucode/agent-runtime.uc"
done
! grep -Eq 'args:.*(command|url|path|package|service)' "$LUCI/root/usr/share/rpcd/ucode/agent-runtime.uc"
! grep -Eq '\beval\b' "$LUCI/root/usr/libexec/agent-runtime-rpcd-job"

python3 -m json.tool "$LUCI/root/usr/share/luci/menu.d/luci-app-agent-runtime.json" >/dev/null
python3 -m json.tool "$LUCI/root/usr/share/rpcd/acl.d/luci-app-agent-runtime.json" >/dev/null

echo 'package layout guard passed'
