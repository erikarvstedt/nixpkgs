{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.paperless-ng;

  defaultUser = "paperless";

  env = {
    PAPERLESS_DATA_DIR = cfg.dataDir;
    PAPERLESS_MEDIA_ROOT = cfg.mediaDir;
    PAPERLESS_CONSUMPTION_DIR = cfg.consumptionDir;
    GUNICORN_CMD_ARGS = "--bind=${cfg.address}:${toString cfg.port}";
  } // cfg.extraConfig;

  manage = let
    setupEnv = lib.concatStringsSep "\n" (mapAttrsToList (name: val: "export ${name}=\"${val}\"") env);
  in pkgs.writeShellScript "manage" ''
    ${setupEnv}
    exec ${cfg.package}/bin/paperless-ng "$@"
  '';

  # Secure the services
  defaultServiceConfig = {
    BindReadOnlyPaths = [
      "/nix/store"
      "-/etc/resolv.conf"
      "-/etc/nsswitch.conf"
      "-/etc/hosts"
      "-/etc/localtime"
    ];
    BindPaths = [
      cfg.consumptionDir
      cfg.dataDir
      cfg.mediaDir
    ];
    CapabilityBoundingSet = "";
    # ProtectClock= adds DeviceAllow=char-rtc r
    DeviceAllow = "";
    # User is set explicitely
    #DynamicUser = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateMounts = true;
    # Needs to communicate to redis
    #PrivateNetwork = true;
    PrivateTmp = true;
    PrivateUsers = true;
    ProcSubset = "pid";
    ProtectClock = true;
    # Breaks if the home dir of the user is in /home
    #ProtectHome = true;
    ProtectHostname = true;
    ProtectSystem = "strict";
    ProtectControlGroups = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [ "@system-service" "~@privileged @resources @setuid @keyring" ];
    TemporaryFileSystem = "/:ro";
    UMask = "0066";
  };
in
{
  options.services.paperless-ng = {
    enable = mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable Paperless-ng.

        When started, the Paperless database is automatically created if it doesn't
        exist and updated if the Paperless package has changed.
        Both tasks are achieved by running a Django migration.

        A script to manage the Paperless instance (by wrapping Django's manage.py) is linked to
        <literal>''${dataDir}/paperless-ng-manage</literal>.
      '';
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/paperless";
      description = "Directory to store the Paperless data.";
    };

    mediaDir = mkOption {
      type = types.str;
      default = "${cfg.dataDir}/media";
      defaultText = "\${dataDir}/consume";
      description = "Directory to store the Paperless documents.";
    };

    consumptionDir = mkOption {
      type = types.str;
      default = "${cfg.dataDir}/consume";
      defaultText = "\${dataDir}/consume";
      description = "Directory from which new documents are imported.";
    };

    consumptionDirIsPublic = mkOption {
      type = types.bool;
      default = false;
      description = "Whether all users can write to the consumption dir.";
    };

    address = mkOption {
      type = types.str;
      default = "localhost";
      description = "Web interface address.";
    };

    port = mkOption {
      type = types.int;
      default = 28981;
      description = "Web interface port.";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Extra paperless-ng config options.

        See <link xlink:href="https://paperless-ng.readthedocs.io/en/latest/configuration.html">the documentation</link>
        for available options.
      '';
      example = literalExample ''
        {
          PAPERLESS_OCR_LANGUAGE = "deu+eng";
        }
      '';
    };

    user = mkOption {
      type = types.str;
      default = defaultUser;
      description = "User under which Paperless runs.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.paperless-ng;
      defaultText = "pkgs.paperless-ng";
      description = "The Paperless package to use.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.paperless.enable ->
          (config.services.paperless.dataDir != cfg.dataDir && config.services.paperless.port != cfg.port);
        message = "Paperless-ng replaces Paperless, either disable Paperless or assign a new dataDir and port to one of them";
      }
    ];

    # Enable redis if no special url is set
    services.redis.enable = mkIf (!hasAttr "PAPERLESS_REDIS" env) true;

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' - ${cfg.user} ${config.users.users.${cfg.user}.group} - -"
      "d '${cfg.mediaDir}' - ${cfg.user} ${config.users.users.${cfg.user}.group} - -"
      (if cfg.consumptionDirIsPublic then
        "d '${cfg.consumptionDir}' 777 - - - -"
      else
        "d '${cfg.consumptionDir}' - ${cfg.user} ${config.users.users.${cfg.user}.group} - -"
      )
    ];

    systemd.services.paperless-ng-consumer = {
      description = "Paperless document consumer";
      serviceConfig = defaultServiceConfig // {
        User = cfg.user;
        ExecStart = "${cfg.package}/bin/paperless-ng document_consumer";
        Restart = "on-failure";
      };
      environment = env;
      after = [ "systemd-tmpfiles-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ln -sf ${manage} ${cfg.dataDir}/paperless-ng-manage

        # Auto-migrate on first run or if the package has changed
        versionFile="${cfg.dataDir}/src-version"
        if [[ $(cat "$versionFile" 2>/dev/null) != ${cfg.package} ]]; then
          ${cfg.package}/bin/paperless-ng migrate
          echo ${cfg.package} > "$versionFile"
        fi
      '';
    };

    systemd.services.paperless-ng-server = {
      description = "Paperless document server";
      serviceConfig = defaultServiceConfig // {
        User = cfg.user;
        ExecStart = "${cfg.package}/bin/paperless-ng qcluster";
        Restart = "on-failure";
      };
      environment = env;
      # Bind to `paperless-ng-consumer` so that the server never runs
      # during migrations
      bindsTo = [ "paperless-ng-consumer.service" ];
      after = [ "paperless-ng-consumer.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.paperless-ng-web = {
      description = "Paperless web server";
      serviceConfig = defaultServiceConfig // {
        User = cfg.user;
        ExecStart = ''
          ${pkgs.python3Packages.gunicorn}/bin/gunicorn \
            -c ${cfg.package}/lib/paperless-ng/gunicorn.conf.py paperless.asgi:application
        '';
        Restart = "on-failure";

        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
        # gunicorn needs setuid
        SystemCallFilter = [ "@system-service" "~@privileged @resources @keyring" "@setuid" ];
      };
      environment = env // {
        PATH = mkForce cfg.package.path;
        PYTHONPATH = "${cfg.package.pythonPath}:${cfg.package}/lib/paperless-ng/src";
      };
      # Bind to `paperless-ng-consumer` so that the server never runs
      # during migrations
      bindsTo = [ "paperless-ng-consumer.service" ];
      after = [ "paperless-ng-consumer.service" ];
      wantedBy = [ "multi-user.target" ];
    };

    users = optionalAttrs (cfg.user == defaultUser) {
      users.${defaultUser} = {
        group = defaultUser;
        uid = config.ids.uids.paperless;
        home = cfg.dataDir;
      };

      groups.${defaultUser} = {
        gid = config.ids.gids.paperless;
      };
    };
  };
}
