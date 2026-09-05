# SPDX-License-Identifier: MIT

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-agent-runtime
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=hotwa

LUCI_TITLE:=LuCI Agent Runtime Manager
LUCI_DESCRIPTION:=Safe local management interface for optional agent runtimes
LUCI_DEPENDS:=+agent-runtime +luci-base +rpcd-mod-ucode +ucode-mod-fs
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/postinst
#!/bin/sh
root="$${IPKG_INSTROOT:-}"
chmod 0755 "$$root/usr/libexec/agent-runtime-rpcd-job"
[ -n "$$root" ] || {
	rm -f /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache/
	/etc/init.d/rpcd reload 2>/dev/null || true
}
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk
