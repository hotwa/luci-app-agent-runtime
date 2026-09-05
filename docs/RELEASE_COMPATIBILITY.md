# Release compatibility

The release workflow builds the source feed through the official OpenWrt SDK
action in four lanes:

| Lane | SDK family | Architectures | Expected package format |
| --- | --- | --- | --- |
| Stable | OpenWrt 24.10 | x86_64, aarch64_cortex-a53 | IPK |
| Snapshot | OpenWrt main | x86_64, aarch64_cortex-a53 | APK |

The package is marked `all`, but each lane validates the actual SDK-generated
file extension and stores its package index. This prevents a release from
claiming an APK/IPK that was not produced.

ImmortalWrt is source-compatible for this feed only when its exact SDK provides
the declared LuCI/rpcd/ucode dependencies. Use the exact SDK shipped for the
device's ImmortalWrt release, add this repository as a local feed, and compile
`agent-runtime` plus `luci-app-agent-runtime`. A future CI lane may be added
only after its SDK URL/image and checksum are pinned; do not substitute a
moving branch or an unrelated OpenWrt SDK and call the output ImmortalWrt.
