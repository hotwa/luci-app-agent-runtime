# OpenWrt and ImmortalWrt feed integration

## Build from source feed

For OpenWrt or ImmortalWrt buildroots, use an immutable tag or commit:

```sh
echo 'src-git agent_runtime https://github.com/hotwa/luci-app-agent-runtime.git;v0.1.0' >> feeds.conf.default
./scripts/feeds update agent_runtime
./scripts/feeds install -a -p agent_runtime
```

Enable both packages in the target configuration:

```text
CONFIG_PACKAGE_agent-runtime=y
CONFIG_PACKAGE_luci-app-agent-runtime=y
```

The repository deliberately places package directories below `packages/`. The
OpenWrt feed scanner discovers package Makefiles recursively; do not clone only
the LuCI subdirectory because it depends on the `agent-runtime` core package.

## Install a release artifact

Use only an artifact whose SDK lineage and package format match the device:

| Device package manager | Artifact type |
| --- | --- |
| OpenWrt 24.10 and older | `.ipk`, installed with `opkg install` |
| OpenWrt snapshot / 25.12 and newer | `.apk`, installed with `apk add` |
| ImmortalWrt | Build this feed with the exact ImmortalWrt SDK matching the installed release and target ABI. |

The `agent-runtime` package is architecture independent, but its dependencies
are not. Never install an x86 SDK artifact on aarch64 or vice versa, and never
cross-install APK and IPK packages.

Package signatures are optional only for development builds. Production feeds
must configure the release workflow's `IPK_SIGNING_KEY` and `APK_SIGNING_KEY`
GitHub secrets, publish the corresponding public keys, and install only from a
trusted HTTPS origin.

## OpenWRT-CI integration

During migration, replace a local package copy with two pinned upstream fetches:

```sh
UPDATE_PACKAGE "agent-runtime" "hotwa/luci-app-agent-runtime" "v0.1.0" "pkg"
UPDATE_PACKAGE "luci-app-agent-runtime" "hotwa/luci-app-agent-runtime" "v0.1.0" "pkg"
```

Because this repository has two packages, the consuming script must retain both
`agent-runtime` and `luci-app-agent-runtime` directories. Do not track `main`
in production firmware; update the pinned tag after CI and a real-device gate.
