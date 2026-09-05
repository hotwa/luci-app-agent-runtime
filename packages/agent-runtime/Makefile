# SPDX-License-Identifier: MIT

include $(TOPDIR)/rules.mk

PKG_NAME:=agent-runtime
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=hotwa

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Safe local agent runtime observer
  DEPENDS:=+usign +jsonfilter +wget-ssl
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  A constrained local status and signature-check interface for optional
  OpenWrt agent runtimes. It does not install arbitrary payloads or run
  arbitrary commands.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/agent-runtime
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/agent-runtime $(1)/etc/config/agent-runtime
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/agent-runtime $(1)/etc/init.d/agent-runtime
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usr/sbin/agent-runtime $(1)/usr/sbin/agent-runtime
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || /etc/init.d/agent-runtime enable 2>/dev/null || true
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
