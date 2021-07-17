# Configuration for the Name Service Switch (/etc/nsswitch.conf).

{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    system.nssModules = mkOption {
      type = types.listOf types.package;
      internal = true;
      default = [];
      description = ''
        Path containing NSS (Name Service Switch) modules.
        This allows several DNS resolution methods to be specified via
        <filename>/etc/nsswitch.conf</filename>.
      '';
      apply = list:
        {
          inherit list;
          path = pkgs.symlinkJoin {
            name = "nss-modules";
            paths = list;
          };
        };
    };

    system.nssDatabases = {
      passwd = mkOption {
        type = types.listOf types.str;
        description = ''
          List of passwd entries to configure in <filename>/etc/nsswitch.conf</filename>.
        '';
        default = [];
      };

      group = mkOption {
        type = types.listOf types.str;
        description = ''
          List of group entries to configure in <filename>/etc/nsswitch.conf</filename>.
        '';
        default = [];
      };

      shadow = mkOption {
        type = types.listOf types.str;
        description = ''
          List of shadow entries to configure in <filename>/etc/nsswitch.conf</filename>.
        '';
        default = [];
      };

      hosts = mkOption {
        type = types.listOf types.str;
        description = ''
          List of hosts entries to configure in <filename>/etc/nsswitch.conf</filename>.
        '';
        default = [];
      };

      services = mkOption {
        type = types.listOf types.str;
        description = ''
          List of services entries to configure in <filename>/etc/nsswitch.conf</filename>.
        '';
        default = [];
      };
    };
  };

  imports = [
    (mkRenamedOptionModule [ "system" "nssHosts" ] [ "system" "nssDatabases" "hosts" ])
  ];

  config = {
    assertions = let
      systemGlibc = pkgs.stdenv.glibc.outPath;
      incompatibleModules = builtins.filter (module: module.stdenv.glibc.outPath != systemGlibc)
        config.system.nssModules.list;
    in [
      { assertion = (incompatibleModules == []);
        message = ''
          The following NSS modules don't use the system glibc derivation.
          They can fail due to ABI incompatibilities. Please remove them:
          ${concatMapStringsSep "\n" (builtins.getAttr "name") incompatibleModules}
        '';
      }
    ];

    # Provide NSS modules at a glibc-specific path in /run
    # See ../../../pkgs/development/libraries/glibc/add-extra-module-load-path.patch
    # for further details.
    systemd.tmpfiles.rules = let
      prefixLen = builtins.stringLength builtins.storeDir + 1;
      hashLen = 32;
      glibcStorePathHash = builtins.substring prefixLen hashLen pkgs.glibc.outPath;
    in [
      "L+ /run/nss-modules-${glibcStorePathHash} - - - - ${config.system.nssModules.path}"
    ];

    # Name Service Switch configuration file.  Required by the C
    # library.
    environment.etc."nsswitch.conf".text = ''
      passwd:    ${concatStringsSep " " config.system.nssDatabases.passwd}
      group:     ${concatStringsSep " " config.system.nssDatabases.group}
      shadow:    ${concatStringsSep " " config.system.nssDatabases.shadow}

      hosts:     ${concatStringsSep " " config.system.nssDatabases.hosts}
      networks:  files

      ethers:    files
      services:  ${concatStringsSep " " config.system.nssDatabases.services}
      protocols: files
      rpc:       files
    '';

    system.nssDatabases = {
      passwd = mkBefore [ "files" ];
      group = mkBefore [ "files" ];
      shadow = mkBefore [ "files" ];
      hosts = mkMerge [
        (mkOrder 998 [ "files" ])
        (mkOrder 1499 [ "dns" ])
      ];
      services = mkBefore [ "files" ];
    };
  };
}
