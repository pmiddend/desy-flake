{ pkgs, simplon-stub, asapo-module }:
pkgs.nixosTest {
  name = "wait-for-services";

  nodes = {
    server = { pkgs, ... }: {
      imports = [
        asapo-module
        simplon-stub.nixosModules.simplon-stub
      ];

      services.asapo.enable = true;

      services.simplon-stub = {
        enable = true;
        input-h5-file = pkgs.requireFile {
          name = "178_data-00000.nx5";
          sha256 = "1hnhff25zj5phii0p8svvnxlvjmhgwwzhbbyf9d38vbr8i07ysdp";
          message = "Please put 178_data-00000.nx5 into the Nix store so we can use it in the test";
        };
      };

      # services.tango-controls.enable = true;
      # services.mysql.package = pkgs.mariadb;
      # services.mysql.enable = true;

      # systemd.services.p11-dummy-energy =
      #   {
      #     after = [ "network.target" "tango.target" ];

      #     serviceConfig = {
      #       User = "asapo";
      #       Group = "asapo";
      #       ExecStart = "${tapedrive-runner.packages.${system}.default}/bin/TapeDriveRunner dev_tapedrive";
      #     };
      #   };


      environment.systemPackages = [ pkgs.asapo-examples ];
    };
  };

  testScript =
    ''
      start_all()
      server.wait_for_unit("influxdb")
      server.wait_for_unit("nginx")
      server.wait_for_unit("asapo-monitoring-server")

      # Check that influxdb is up and running
      server.wait_until_succeeds("curl -f http://localhost:8400/influxdb/health", timeout=10)

      server.wait_for_open_port(8400)
      server.wait_for_open_port(8410)
      server.wait_for_open_port(8411)
      server.wait_for_open_port(8412)
      server.wait_for_open_port(8413)
      server.wait_for_open_port(8414)
      server.wait_for_open_port(8420)
      server.wait_for_open_port(8430)
      server.wait_for_open_port(8431)
      server.wait_for_open_port(8086)
      server.wait_for_open_port(27017)
      server.wait_for_unit("asapo-authorizer")
      # This would test the simple producer script
      # server.succeed("asapo-produce")

      server.wait_for_open_port(10001)
    '';
}
