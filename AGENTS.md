# Agent Guide — luci-app-agent-runtime

This repository is an OpenWrt/ImmortalWrt package feed. It deliberately
separates a generic, safe runtime observer from site-specific AI runtimes.

## Package boundaries

- `packages/agent-runtime` owns `/etc/config/agent-runtime`, the fixed-command
  `agent-runtime` CLI, and its non-destructive boot reconciliation.
- `packages/luci-app-agent-runtime` owns only the LuCI view, rpcd ACL and a
  fixed-action asynchronous job launcher.
- Do not add a generic shell, arbitrary URL fetcher, arbitrary file reader, or
  arbitrary service controller to either RPC interface.
- Node, uv, Pi, CommandCode, Multica and any signed runtime payload are
  optional integrations. They are not downloaded or embedded by this feed.

## Security and release rules

- Never commit auth keys, signing keys, package repository keys, release URLs
  containing credentials, device state, cookies, or `/data` content.
- Every new LuCI mutation must be a fixed, separately authorised RPC method,
  must produce bounded output, and must have a test.
- Keep package payloads POSIX `ash` compatible. Do not introduce Bash, Python,
  Node, or native compilation dependencies into the core package.
- A release tag is immutable. Change `PKG_VERSION` deliberately and allow the
  release workflow to build both the IPK and APK SDK matrices.

## Verification

Run before committing:

```sh
sh -n packages/agent-runtime/files/usr/sbin/agent-runtime
sh -n packages/agent-runtime/files/etc/init.d/agent-runtime
sh -n packages/luci-app-agent-runtime/root/usr/libexec/agent-runtime-rpcd-job
sh tests/test_package_layout.sh
sh tests/test_agent_runtime_cli.sh
git diff --check
```
