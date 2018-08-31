{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.paperless;

  defaultUser = "paperless";
in
{
  options.services.paperless = {
    enable = mkEnableOption "Paperless";

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/paperless";
      description = "Directory to store the Paperless data.";
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
      description = "Server port.";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Extra paperless config options.

        See <literal>paperless-src/paperless.conf.example</literal> for available options.

        To define secret options without storing them in /nix/store, use the following pattern:
        <literal>PAPERLESS_PASSPHRASE = "$(&lt; /etc/my_passphrase_file)"</literal>
      '';
      example = literalExample ''
        {
          PAPERLESS_OCR_LANGUAGE = "deu";
        }
      '';
    };

    autoSetupDB = mkOption {
      type = types.bool;
      default = true;
      description = ''
        When enabled, the database is automatically created when it doesn't exist and updated
        when the Paperless package has changed.
        Both tasks are achieved by running a Django migration.
      '';
    };

    user = mkOption {
      type = types.str;
      default = defaultUser;
      description = "User under which Paperless runs.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.paperless;
      defaultText = "pkgs.paperless";
      description = "The Paperless package to use.";
    };
  };

  config = mkIf cfg.enable (
    let
      runner = cfg.package.withConfig {
        config = {
          PAPERLESS_DISABLE_LOGIN = "true";
          PAPERLESS_CONSUMPTION_DIR = cfg.consumptionDir;
        } // cfg.extraConfig;
        inherit (cfg) dataDir;
        paperlessDrv = cfg.package;
      };

      setupDB = ''
        if [[ ! -e "${cfg.dataDir}" ]]; then
          install -o ${cfg.user} -g $(id -gn ${cfg.user}) -d "${cfg.dataDir}"
        fi
        ${optionalString cfg.consumptionDirIsPublic ''
          if [[ ! -e "${cfg.consumptionDir}" ]]; then
            install -o ${cfg.user} -g $(id -gn ${cfg.user}) -m 777 -d "${cfg.consumptionDir}"
          fi
        ''}
        exec ${pkgs.libuuid}/bin/runuser -u "${cfg.user}" -- ${migrate}
      '';

      migrate = pkgs.writeScript "migrate" ''
        #!${pkgs.stdenv.shell} -e
        ${runner.setupEnv}
        versionFile="$PAPERLESS_DBDIR/src-version"

        if [[ $(cat "$versionFile" 2>/dev/null) != ${cfg.package} ]]; then
          python $paperlessSrc/manage.py migrate
          echo ${cfg.package} > "$versionFile"
        fi
      '';
    in
      {
        systemd.services.paperless-consumer = {
          description = "Paperless document consumer";
          serviceConfig = {
            PermissionsStartOnly = true;
            User = cfg.user;
            ExecStart = "${runner} document_consumer";
            Restart = "always";
          };
          wantedBy = [ "multi-user.target" ];
        } // (optionalAttrs cfg.autoSetupDB {
          # Auto-migrate on first run or if the package has changed
          preStart = setupDB;
        });

        systemd.services.paperless-server = {
          description = "Paperless document server";
          serviceConfig = {
            User = cfg.user;
            ExecStart = "${runner} runserver --noreload ${cfg.address}:${toString cfg.port}";
            Restart = "always";
          };
          # Bind to `paperless-consumer` so that the server never runs
          # during migrations
          bindsTo = [ "paperless-consumer.service" ];
          after = [ "paperless-consumer.service" ];
          wantedBy = [ "multi-user.target" ];
        };

        users = optionalAttrs (cfg.user == defaultUser) {
          users = [{
            name = defaultUser;
            group = defaultUser;
            uid = config.ids.uids.paperless;
            home = cfg.dataDir;
          }];

          groups = [{
            name = defaultUser;
            gid = config.ids.gids.paperless;
          }];
        };
      }
  );
}
