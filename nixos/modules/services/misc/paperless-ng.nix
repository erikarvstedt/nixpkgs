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

  setupEnv = lib.concatStringsSep "\n" (mapAttrsToList (name: val: "export ${name}=\"${val}\"") env);
  manage = pkgs.writeShellScript "manage" ''
    ${setupEnv}
    exec ${cfg.package}/bin/paperless-ng "$@"
  '';
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
      description = "Server listening address.";
    };

    port = mkOption {
      type = types.int;
      default = 28981;
      description = "Server port to listen on.";
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
      serviceConfig = {
        User = cfg.user;
        ExecStart = "${cfg.package}/bin/paperless-ng document_consumer";
        Restart = "on-failure";
      };
      environment = env;
      after = [ "systemd-tmpfiles-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        if [[ $(readlink ${cfg.dataDir}/paperless-ng-manage) != ${manage} ]]; then
          ln -sf ${manage} ${cfg.dataDir}/paperless-ng-manage
        fi

        ${setupEnv}
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
      serviceConfig = {
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
      serviceConfig = {
        User = cfg.user;
        ExecStart = ''
          ${pkgs.python3Packages.gunicorn}/bin/gunicorn \
            -c ${cfg.package}/lib/paperless-ng/gunicorn.conf.py paperless.asgi:application
        '';
        Restart = "on-failure";
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
