{
  apk-tools,
  fakeroot,
  fetchFromGitHub,
  lib,
  lua,
  nix-update-script,
  stdenvNoCC,
}:

let
  release = "1";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "openwrt-passwall";
  version = "26.8.12";
  __structuredAttrs = true;
  strictDeps = true;

  sourceRoot = "${finalAttrs.src.name}/luci-app-passwall";
  src = fetchFromGitHub {
    owner = "Openwrt-Passwall";
    repo = "openwrt-passwall";
    tag = "${finalAttrs.version}-${release}";
    hash = "sha256-jQ6NpisfPe/7D/mz9/JlntkvGU2SdsmMOPE2s8rWWgg=";
  };

  nativeBuildInputs = [
    apk-tools
    fakeroot
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    root="$TMPDIR"/package-root
    mkdir --parents "$root"/{www,usr/lib/lua/luci,lib/upgrade/keep.d,lib/apk/packages}

    # Assemble the OpenWrt filesystem layout, mirroring LuCI's luci.mk
    cp --recursive htdocs/. "$root"/www
    cp --recursive luasrc/. "$root"/usr/lib/lua/luci
    cp --recursive root/. "$root"
    echo "/etc/config/passwall" > "$root"/lib/upgrade/keep.d/luci-app-passwall

    chmod --recursive u+w "$root"
    find "$root" -type d -exec chmod 755 {} +
    find "$root" -type f -exec chmod 644 {} +
    chmod 755 "$root"/etc/{init.d/{passwall,passwall_server},uci-defaults/luci-passwall,hotplug.d/iface/98-passwall}
    # File list consumed by OpenWrt's default_postinst() to run uci-defaults
    # and enable/start init scripts on install.
    (cd "$root" && find {etc,usr,www,lib/upgrade} -type f | sed --expression='s|^|/|' | sort) > "$root"/lib/apk/packages/luci-app-passwall.list

    # Config files apk preserves across upgrades.
    cat > "$root"/lib/apk/packages/luci-app-passwall.conffiles <<'EOF'
    /etc/config/passwall
    /etc/config/passwall_server
    /usr/share/passwall/rules/direct_host
    /usr/share/passwall/rules/direct_ip
    /usr/share/passwall/rules/proxy_host
    /usr/share/passwall/rules/proxy_ip
    /usr/share/passwall/rules/block_host
    /usr/share/passwall/rules/block_ip
    /usr/share/passwall/rules/lanlist_ipv4
    /usr/share/passwall/rules/lanlist_ipv6
    /usr/share/passwall/rules/domains_excluded
    EOF

    # Shipped files that are always restored with their pristine content.
    {
      printf '%s %s\n' /etc/config/passwall_server "$(sha1sum "$root"/etc/config/passwall_server | cut --delimiter=' ' --fields=1)"
      for f in "$root"/usr/share/passwall/rules/*; do
        printf '%s %s\n' "/usr/share/passwall/rules/$(basename "$f")" "$(sha1sum "$f" | cut --delimiter=' ' --fields=1)"
      done
    } > "$root"/lib/apk/packages/luci-app-passwall.conffiles_static

    cat > "$TMPDIR"/post-install <<'EOF'
    #!/bin/sh
    [ "''${IPKG_NO_SCRIPT}" = "1" ] && exit 0
    [ -s "''${IPKG_INSTROOT}"/lib/functions.sh ] || exit 0
    . "''${IPKG_INSTROOT}"/lib/functions.sh
    export root="''${IPKG_INSTROOT}"
    export pkgname="luci-app-passwall"
    add_group_and_user
    default_postinst
    [ -n "''${IPKG_INSTROOT}" ] || {
      rm -f /tmp/luci-indexcache.*
      rm -rf /tmp/luci-modulecache/
      /etc/init.d/rpcd reload 2>/dev/null
      exit 0
    }
    EOF
    cat > "$TMPDIR"/post-upgrade <<'EOF'
    #!/bin/sh
    export PKG_UPGRADE=1
    [ "''${IPKG_NO_SCRIPT}" = "1" ] && exit 0
    [ -s "''${IPKG_INSTROOT}"/lib/functions.sh ] || exit 0
    . "''${IPKG_INSTROOT}"/lib/functions.sh
    export root="''${IPKG_INSTROOT}"
    export pkgname="luci-app-passwall"
    add_group_and_user
    default_postinst
    [ -n "''${IPKG_INSTROOT}" ] || {
      rm -f /tmp/luci-indexcache.*
      rm -rf /tmp/luci-modulecache/
      /etc/init.d/rpcd reload 2>/dev/null
      exit 0
    }
    EOF
    cat > "$TMPDIR"/pre-deinstall <<'EOF'
    #!/bin/sh
    [ -s "''${IPKG_INSTROOT}"/lib/functions.sh ] || exit 0
    . "''${IPKG_INSTROOT}"/lib/functions.sh
    export root="''${IPKG_INSTROOT}"
    export pkgname="luci-app-passwall"
    default_prerm
    EOF
    cat > "$TMPDIR"/post-deinstall <<'EOF'
    #!/bin/sh
    rm -f "''${IPKG_INSTROOT}"/usr/share/passwall/rules/*.nft
    exit 0
    EOF

    mkdir --parents "$out"
    export PKG_ROOT="$root"
    export PKG_OUT="$out/luci-app-passwall_${finalAttrs.version}-r${release}.apk"
    # Record root:root ownership in the package metadata via fakeroot
    fakeroot -- bash -c '
      chown --recursive 0:0 "$PKG_ROOT"
      apk mkpkg \
        --files="$PKG_ROOT" \
        --info=name:luci-app-passwall \
        --info="version:${finalAttrs.version}-r${release}" \
        --info=arch:noarch \
        --info="description:LuCI support for PassWall" \
        --info="maintainer:OpenWrt LuCI community" \
        --info="url:https://github.com/openwrt/luci" \
        --info="license:GPL-3.0-only" \
        --info="depends:coreutils coreutils-base64 coreutils-nohup coreutils-timeout curl chinadns-ng dns2socks dnsmasq-full ip-full libc libuci-lua lua luci-compat luci-lib-jsonc luci-lua-runtime microsocks resolveip tcping lyaml" \
        --info="provides:luci-app-passwall-any" \
        --script=post-install:"$TMPDIR"/post-install \
        --script=post-upgrade:"$TMPDIR"/post-upgrade \
        --script=pre-deinstall:"$TMPDIR"/pre-deinstall \
        --script=post-deinstall:"$TMPDIR"/post-deinstall \
        --output="$PKG_OUT"
    '

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LuCI support for PassWall";
    homepage = "https://github.com/Openwrt-Passwall/openwrt-passwall";
    changelog = "https://github.com/Openwrt-Passwall/openwrt-passwall/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ yiyu ];
    inherit (lua.meta) platforms;
  };
})
