{ callPackage }:

rec {
  connman = callPackage ./connman.nix {};

  connmanMinimal = callPackage ./connman.nix {
    openconnect = null;
    openvpn = null;
    vpnc = null;
    polkit = null;
    pptp = null;
    ppp = null;
  };

  connmanFull = connman.overrideDerivation (old: {
    configureFlags = old.configureFlags ++ [
      "--enable-nmcompat"
      "--enable-hh2serial-gps"
      "--enable-l2tp"
      "--enable-iospm"
      "--enable-tist"
    ];
  });
}
