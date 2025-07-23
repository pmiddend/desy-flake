{ pkgs, simplon-stub, asapo-module }:
pkgs.nixosTest {
  name = "wait-for-services";

  nodes = {
    server = { pkgs, ... }: {
      imports = [
        asapo-module
        simplon-stub.nixosModules.simplon-stub
      ];

      services.asapo = {
        enable = true;
        tokens-path = "/var/lib/asapo/token.txt";
      };

      services.simplon-stub = {
        enable = true;
        input-h5-file = pkgs.requireFile {
          name = "178_data-00000.nx5";
          sha256 = "1hnhff25zj5phii0p8svvnxlvjmhgwwzhbbyf9d38vbr8i07ysdp";
          message = "Please put 178_data-00000.nx5 into the Nix store so we can use it in the test";
        };
      };

      systemd.services.asapo_eiger_connector =
        {
          description = "ASAP:O Eiger connector";
          requires = [ "asapo.target" ];
          after = [ "simplon-stub.service" "asapo.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            User = "asapo";
            Group = "asapo";

            ExecStart = pkgs.writeShellScript "asapo_eiger_connector-start.sh" ''
              ${pkgs.asapo_eiger_connector}/bin/asapo_eiger_connector --zmq_host 0.0.0.0 --zmq_port 9999 --endpoint localhost:8400 --ignore_series_id --beamtime asapo_test --beamline auto --token $(cat /var/lib/asapo/token.txt | tr -d '\n') --debug
            '';
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


      environment.systemPackages = [ pkgs.asapo-examples pkgs.crystfel-headless ];
    };
  };

  testScript = ''
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
    server.wait_for_unit("asapo_eiger_connector")

    def set_config_value(subsystem: str, name: str, value: int | float | str) -> None:
      import json
      print(f"setting {name} to {value}")
      server.wait_until_succeeds("curl -X PUT -f http://localhost:10001/"+subsystem+"/api/1.8.0/config/"+name+" --data '{ \"value\": "+json.dumps(value)+" }'", timeout=10)

    def send_command(subsystem: str, command: str) -> None:
      server.wait_until_succeeds("curl -X PUT -f http://localhost:10001/"+subsystem+"/api/1.8.0/command/"+command, timeout=10)

    set_config_value("detector", "ntrigger", 1)
    set_config_value("detector", "nimages", 2)
    set_config_value("detector", "ntrigger", 1)
    set_config_value("detector", "frame_time", 1.0)
    set_config_value("detector", "count_time", 1.0)
    set_config_value("detector", "trigger_mode", "ints")
    set_config_value("stream", "mode", "enabled")
    set_config_value("stream", "header_appendix", '{"series_name": "1"}')
    set_config_value("stream", "image_appendix", '{"series_name": "1"}')

    send_command("detector", "arm")
    send_command("detector", "trigger")

    from pathlib import Path
    with Path("test-geom.geom").open("w+", encoding="utf-8") as f:
        f.write("""
          photon_energy = 12000 eV
          clen = 0.1986
          bandwidth = 1.000000e-08
          coffset = 0.000000
          res = 13333.300000
          data = /entry/data/data
          flag_morethan = 65534
          adu_per_photon = 1.000000
          dim0 = %
          dim1 = ss
          dim2 = fs

          panel0/min_fs = 0
          panel0/max_fs = 4147
          panel0/min_ss = 0
          panel0/max_ss = 4361
          panel0/corner_x = 2139.097467
          panel0/corner_y = 2182.737834
          panel0/fs = -1.000000x +0.000000y +0.000000z
          panel0/ss = 0.000000x -1.000000y +0.000000z

          group_all = panel0
        """)

    server.copy_from_host("test-geom.geom", "/tmp/test-geom.geom")

    with Path("beamtime-metadata-11010000.json").open("w+", encoding="utf-8") as f:
        f.write("""
                    {
                      "applicant": {
                        "email": "test",
                        "institute": "test",
                        "lastname": "test",
                        "userId": "1234",
                        "username": "test"
                      },
                      "beamline": "p07",
                      "beamline_alias": "P07",
                      "beamtimeId": "asapo_test",
                      "contact": "None",
                      "corePath": "/asap3/petra3/gpfs/p07/2020/data/11111111",
                      "event-end": "2020-03-03 09:00:00",
                      "event-start": "2020-03-02 09:00:00",
                      "facility": "PETRA III",
                      "generated": "2020-02-22 22:37:16",
                      "pi": {
                        "email": "test",
                        "institute": "test",
                        "lastname": "test",
                        "userId": "14",
                        "username": "test"
                      },
                      "proposalId": "12345678",
                      "proposalType": "H",
                      "title": "In-House Research (P07)",
                      "unixId": "None",
                      "users": {
                        "door-db": [
                          "test"
                        ],
                        "special": [],
                        "unknown": []
                      }
                    }
        """)
    server.copy_from_host("beamtime-metadata-11010000.json", "/var/lib/asapo/beamlines/asapo_test/current/beamtime-metadata-11010000.json")

    server.wait_until_succeeds("indexamajig --data-format=seedee --asapo-endpoint=localhost:8400 --asapo-token=$(cat /var/lib/asapo/token.txt | tr -d '\n') --asapo-beamtime=asapo_test --asapo-source detector --asapo-consumer-timeout=3000 --no-data-timeout=15 --asapo-stream=1 --asapo-wait-for-stream --asapo-group=online -g /tmp/test-geom.geom -o output.stream")
  '';
}
