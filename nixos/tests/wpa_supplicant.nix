import ./make-test-python.nix ({ pkgs, lib, ...}:
{
  name = "wpa_supplicant";
  meta = with lib.maintainers; {
    maintainers = [ rnhmjoj ];
  };

  machine = { ... }: {
    imports = [ ../modules/profiles/minimal.nix ];

    # add a virtual wlan interface
    boot.kernelModules = [ "mac80211_hwsim" ];

    # wireless access point
    services.hostapd = {
      enable = true;
      wpa = true;
      interface = "wlan0";
      ssid = "nixos-test";
      wpaPassphrase = "reproducibility";
    };

    # wireless client
    networking.wireless = {
      enable = lib.mkOverride 0 true;
      userControlled.enable = true;
      interfaces = [ "wlan1" ];

      networks = {
        # test network
        nixos-test.psk = "reproducibility";

        # secrets substitution test cases
        test1.psk = "@PSK_VALID@";              # should be replaced
        test2.psk = "@PSK_MISSING@";            # should not be replaced
        test3.psk = "P@ssowrdWithSome@tSymbol"; # should not be replaced
        test4.psk = "@PSK_NASTY@";              # should be replaced
      };

      # secrets
      environmentFile = pkgs.writeText "wpa-secrets" ''
        PSK_VALID="S0m3BadP4ssw0rd";
        PSK_NASTY=",./;'[]\-= <>?:\"{}|_+ !@#$%^\&*()`~";
      '';
    };

  };

  testScript =
    ''
      start_all()

      config_file = "/run/wpa_supplicant/wpa_supplicant.conf"

      with subtest("Configuration file has the right permissions"):
          machine.wait_for_file(config_file)
          mode = machine.succeed(f"stat -c '%a' {config_file}").strip()
          assert mode == "600", f"expected: 600, found: {mode}"

      with subtest("Secrets variables have been substituted"):
          machine.fail(f"grep -q @PSK_VALID@ {config_file}")
          machine.succeed(f"grep -q @PSK_MISSING@ {config_file}")
          machine.succeed(f"grep -q P@ssowrdWithSome@tSymbol {config_file}")
          machine.fail(f"grep -q PSK_NASTY {config_file}")

          # save file for manual inspection
          machine.copy_from_vm(config_file)

      with subtest("Daemon is running and accepting connections"):
          machine.wait_for_unit("wpa_supplicant-wlan1.service")
          status = machine.succeed("wpa_cli -i wlan1 status")
          assert "Failed to connect" not in status, \
                 "Failed to connect to the daemon"

      with subtest("Daemon can connect to the access point"):
          machine.wait_until_succeeds(
            "wpa_cli -i wlan1 status | grep -q wpa_state=COMPLETED"
          )
    '';
})

