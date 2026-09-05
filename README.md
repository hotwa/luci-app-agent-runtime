# Agent Runtime for OpenWrt / ImmortalWrt

`luci-app-agent-runtime` is a lightweight, modern LuCI control surface for an
agent runtime on an OpenWrt-family device. It is a reusable **package feed**:
the UI and the `agent-runtime` core can be installed without rebuilding a
whole firmware image.

The project intentionally does not ship an AI model, account, secret, browser
session, Node.js distribution, or a generic remote shell. It observes a local
runtime, validates an optional signed release index, and gives integrators a
safe place to expose explicit runtime capabilities.

## Packages

| Package | Purpose |
| --- | --- |
| `agent-runtime` | UCI configuration, status/check/verify/reconcile CLI and a non-destructive init hook. |
| `luci-app-agent-runtime` | LuCI dashboard, restricted rpcd API, fixed-action background job interface. |

Both payloads are architecture-independent shell/JavaScript resources
(`PKGARCH:=all`). Release CI still builds them with x86_64 and aarch64 SDKs so
the package metadata matches the target package manager and dependencies.

## Install as a build feed

Pin a release tag or commit in production builds:

```sh
echo 'src-git agent_runtime https://github.com/hotwa/luci-app-agent-runtime.git;v0.1.0' >> feeds.conf.default
./scripts/feeds update agent_runtime
./scripts/feeds install -a -p agent_runtime
```

Then select:

```text
CONFIG_PACKAGE_agent-runtime=y
CONFIG_PACKAGE_luci-app-agent-runtime=y
```

For development, cloning this repository into `package/` is also supported:

```sh
git clone https://github.com/hotwa/luci-app-agent-runtime.git package/hotwa-agent-runtime
```

Read [feed integration](docs/FEED_INTEGRATION.md) before installing a release
artifact with `opkg` or `apk`.

## Safe default behaviour

On a clean installation the dashboard is useful immediately: it shows storage
readiness, runtime directories, optional Node/Pi/CommandCode/Multica discovery
and release-index configuration. `check` only downloads the fixed
`index.json` and `index.json.sig` endpoints from a configured HTTPS release
base and verifies them with a configured public `usign` key. It never installs
an archive. `verify` validates an already-present active manifest signature.

Full generation download, activation and service orchestration belong in a
separate, reviewed provider package. This keeps a widely installable LuCI
package from acquiring unbounded root-level capabilities.

## Development

```sh
sh tests/test_package_layout.sh
sh tests/test_agent_runtime_cli.sh
```

The release workflow builds four compatibility artifacts: OpenWrt stable IPK
for x86_64/aarch64 and OpenWrt snapshot APK for x86_64/aarch64. It publishes
checksums with a GitHub Release only for a `v*` tag. ImmortalWrt integrations
should build this same feed against the exact SDK matching the device firmware;
see [release compatibility](docs/RELEASE_COMPATIBILITY.md).
