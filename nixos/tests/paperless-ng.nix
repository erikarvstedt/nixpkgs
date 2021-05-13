import ./make-test-python.nix ({ lib, ... }: {
  name = "paperless-ng";
  meta = {
    maintainers = with lib.maintainers; [ Flakebi ];
  };

  nodes.machine = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ imagemagick jq ];
    services.redis.enable = true;
    services.paperless-ng.enable = true;
    virtualisation.memorySize = 1024;
  };

  testScript = ''
    machine.wait_for_unit("paperless-ng-consumer.service")

    # Create test doc
    machine.succeed(
        "convert -size 400x40 xc:white -font 'DejaVu-Sans' -pointsize 20 -fill black -annotate +5+20 'hello world 16-10-2005' /var/lib/paperless/consume/doc.png"
    )

    with subtest("Service gets ready"):
        machine.wait_for_unit("paperless-ng-web.service")
        # Wait until server accepts connections
        machine.wait_until_succeeds("curl -fs localhost:28981")

    # Create admin user
    machine.succeed("echo \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@localhost', 'admin')\" | /var/lib/paperless/paperless-ng-manage shell")

    with subtest("Test document is consumed"):
        machine.wait_until_succeeds(
            "(($(curl -u admin:admin -fs localhost:28981/api/documents/ | jq .count) == 1))"
        )
        assert "2005-10-16" in machine.succeed(
            "curl -u admin:admin -fs localhost:28981/api/documents/ | jq '.results | .[0] | .created'"
        )
  '';
})
