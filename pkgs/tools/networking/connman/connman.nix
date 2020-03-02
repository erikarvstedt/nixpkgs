{ stdenv
, fetchurl
, pkgconfig
, file
, glib
, dbus
, libmnl
, gnutls
, readline

# these features are enabled by default
, openconnect ? null
, openvpn ? null
, vpnc ? true
, polkit ? null
, pptp ? null
, ppp ? null

# configurable options
, firewallType ? "iptables" # or "nftables"
, iptables ? null
, libnftnl ? null # for nftables
, dnsType ? "internal" # or "systemd-resolved"
}:

assert stdenv.lib.asserts.assertOneOf "firewallType" firewallType [ "iptables" "nftables" ];
assert stdenv.lib.asserts.assertOneOf "dnsType" dnsType [ "internal" "systemd-resolved" ];

let inherit (stdenv.lib) optionals; in

stdenv.mkDerivation rec {
  pname = "connman";
  version = "1.38";
  src = fetchurl {
    url = "mirror://kernel/linux/network/connman/${pname}-${version}.tar.xz";
    sha256 = "0awkqigvhwwxiapw0x6yd4whl465ka8a4al0v2pcqy9ggjlsqc6b";
  };

  buildInputs = [
    glib
    dbus
    libmnl
    gnutls
    readline
    (if (firewallType == "iptables") then iptables else libnftnl)
  ]
    ++ optionals (openvpn != null) [ openvpn ]
    ++ optionals (openconnect != null) [ openconnect ]
    ++ optionals (vpnc != null) [ vpnc ]
    ++ optionals (polkit != null) [ polkit ]
    ++ optionals (pptp != null) [ pptp ppp ]
  ;

  nativeBuildInputs = [
    pkgconfig
    file
  ];

  postPatch = ''
    sed -i "s/\/usr\/bin\/file/file/g" ./configure
  '';

  configureFlags = [
    "--sysconfdir=${placeholder "out"}/etc"
    "--localstatedir=/var"
    "--with-dbusconfdir=${placeholder "out"}/share"
    "--with-dbusdatadir=${placeholder "out"}/share"
    "--with-tmpfilesdir=${placeholder "out"}/lib/tmpfiles.d"
    "--with-systemdunitdir=${placeholder "out"}/lib/systemd/system"
    "--with-dns-backend=${dnsType}"
    "--with-firewall=${firewallType}"
    "--enable-iwd"

    # release build flags
    "--disable-maintainer-mode"
    "--enable-session-policy-local=builtin"

    # for building and running tests
    # "--enable-tests" # installs the tests, we don't want that
    "--enable-tools"
  ]
    ++ optionals (openconnect != null) [
      "--enable-openconnect=builtin"
      "--with-openconnect=${openconnect}/sbin/openconnect"
    ]
    ++ optionals (openvpn != null) [
      "--enable-openvpn=builtin"
      "--with-openvpn=${openvpn}/sbin/openvpn"
    ]
    ++ optionals (vpnc != null) [
      "--enable-vpnc=builtin"
      "--with-vpnc=${vpnc}/sbin/vpnc"
    ]
    ++ optionals (polkit != null) [
      "--enable-polkit"
    ]
    ++ optionals (pptp != null) [
      "--enable-pptp"
      "--with-pptp=${pptp}/sbin/pptp"
    ]
  ;

  doCheck = true;

  meta = with stdenv.lib; {
    description = "A daemon for managing internet connections";
    homepage = "https://01.org/connman";
    maintainers = [ maintainers.matejc ];
    platforms = platforms.linux;
    license = licenses.gpl2;
  };
}
