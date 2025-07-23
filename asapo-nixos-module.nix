{ pkgs, config, lib, default-overlay, ... }:
{
  options.services.asapo = with pkgs.lib; {
    enable = lib.mkEnableOption "enable asapo";

    influxdb-port = mkOption { type = types.port; default = 8086; };
    nginx-port = mkOption { type = types.port; default = 8400; };
    discovery-port = mkOption { type = types.port; default = 8410; };
    broker-port = mkOption { type = types.port; default = 8413; };
    mongo-port = mkOption { type = types.port; default = 27017; };
    authorizer-port = mkOption { type = types.port; default = 8412; };
    file-transfer-port = mkOption { type = types.port; default = 8414; };
    monitoring-port = mkOption { type = types.port; default = 8420; };
    receiver-port = mkOption { type = types.port; default = 8411; };
    receiver-metrics-port = mkOption { type = types.port; default = 8430; };
    receiver-advertiser-port = mkOption { type = types.port; default = 8431; };
    root-beamtimes-folder = mkOption { type = types.path; default = "/var/lib/asapo/beamtimes"; };
    current-beamlines-folder = mkOption { type = types.path; default = "/var/lib/asapo/beamlines"; };
    tokens-path = mkOption { type = types.path; };
    secret-key = mkOption { type = types.str; default = "veryverysecretkey"; };
    secret-key-admin = mkOption { type = types.str; default = "veryverysecretkeyadmin"; };
  };

  config = lib.mkIf config.services.asapo.enable {
    nixpkgs.overlays = [ default-overlay ];

    users.groups.asapo = { };

    users.users.asapo = {
      createHome = true;
      isSystemUser = true;
      home = "/var/lib/asapo";
      group = "asapo";
    };

    services.mongodb = {
      enable = true;
    };

    services.influxdb = {
      enable = true;

      extraConfig = {
        http = {
          flux-enabled = true;
        };
      };
    };

    services.nginx = {
      enable = true;

      virtualHosts = {
        "localhost" = {
          listen = [{ port = config.services.asapo.nginx-port; addr = "0.0.0.0"; }];

          locations."/influxdb/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.asapo.influxdb-port}";
            extraConfig = "rewrite ^/influxdb(/.*) $1 break;";
          };

          locations."/asapo-discovery/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.asapo.discovery-port}";
            extraConfig = "rewrite ^/asapo-discovery(/.*) $1 break;";
          };
        };
      };
    };

    systemd.services.asapo-create-influxdb-databases =
      {
        description = "ASAP:O database creation script";
        after = [ "influxdb.service" ];

        serviceConfig = {
          Type = "oneshot";
          User = "asapo";
          Group = "asapo";

          ExecStart = "${pkgs.writeShellScript "asapo-create-influxdb-databases.sh" ''
                    ${pkgs.influxdb}/bin/influx -execute 'CREATE DATABASE asapo_receivers'
                    ${pkgs.influxdb}/bin/influx -execute 'CREATE DATABASE asapo_brokers'
                    mkdir -p /var/lib/asapo/beamtimes/asapo_test/processed
                  ''}";
        };
      };

    systemd.services.asapo-monitoring-server =
      let
        configFile = pkgs.writeText "config.json"
          ''
            {
                "ThisClusterName": "asapo",
                "ServerPort": ${toString config.services.asapo.monitoring-port},
                "LogLevel": "debug",
                "InfluxDbUrl":"http://localhost:${toString config.services.asapo.nginx-port}/influxdb",
                "InfluxDbDatabase": "asapo_monitoring",
                "RetentionPolicyTime": "12h",
                "GroupingTime": "10m",
                "MaxPoints": 500
            }
          '';
      in
      {
        description = "ASAP:O monitoring server";
        after = [ "network.target" "nginx.service" "influxdb.service" ];
        # meaning: if we start this service, we start the influxdb database service but we don't care about the outcome
        wants = [ "asapo-create-influxdb-databases.service" ];

        serviceConfig = {
          User = "asapo";
          Group = "asapo";
          ExecStart = "${pkgs.asapo-monitoring-server}/bin/monitoring-server -config ${configFile}";
        };
      };

    systemd.services.asapo-discovery =
      let
        configFile = pkgs.writeText "config.json"
          ''
            {
              "Mode": "static",
              "Receiver": {
                "MaxConnections": 32,
                "StaticEndpoints": [ "0.0.0.0:${toString config.services.asapo.receiver-port}" ]
              },
              "Broker": {
                "StaticEndpoint": "0.0.0.0:${toString config.services.asapo.broker-port}"
              },
              "Mongo": {
                "StaticEndpoint": "0.0.0.0:${toString config.services.asapo.mongo-port}"
              },
              "FileTransferService": {
                "StaticEndpoint": "0.0.0.0:${toString config.services.asapo.file-transfer-port}"
              },
              "Monitoring": {
                "StaticEndpoint": "0.0.0.0:${toString config.services.asapo.monitoring-port}"
              },
              "Port": ${toString config.services.asapo.discovery-port},
              "LogLevel": "info"
            }
          '';
      in
      {
        description = "ASAP:O discovery";
        after = [ "network.target" "mongodb.service" ];

        serviceConfig = {
          User = "asapo";
          Group = "asapo";
          ExecStart = "${pkgs.asapo-discovery}/bin/discovery -config ${configFile}";
        };
      };

    systemd.services.asapo-broker =
      let
        configFile = pkgs.writeText "config.json"
          ''
            {
              "DatabaseServer": "localhost:${toString config.services.asapo.mongo-port}",
              "DiscoveryServer": "0.0.0.0:${toString config.services.asapo.discovery-port}",
              "AuthorizationServer": "localhost:${toString config.services.asapo.authorizer-port}",
              "PerformanceDbServer": "localhost:${toString config.services.asapo.influxdb-port}",
              "MonitorPerformance": true,
              "MonitoringServerUrl":"localhost:${toString config.services.asapo.monitoring-port}",
              "CheckResendInterval":0,
              "PerformanceDbName": "db_test",
              "Port": ${toString config.services.asapo.broker-port},
              "LogLevel": "debug"
            }
          '';
      in
      {
        description = "ASAP:O broker";
        after = [ "network.target" "asapo-monitoring-server.service" "asapo-discovery.service" ];
        wants = [ "asapo-create-influxdb-databases.service" "asapo-discovery.service" ];

        serviceConfig = {
          User = "asapo";
          Group = "asapo";
          ExecStart = "${pkgs.asapo-broker}/bin/broker -config ${configFile}";
        };
      };

    systemd.services.asapo-authorizer =
      let
        secretKeyFile = pkgs.writeText "auth_secret.key" config.services.asapo.secret-key;
        secretKeyFileAdmin = pkgs.writeText "auth_secret_admin.key" config.services.asapo.secret-key-admin;

        configFile = pkgs.writeText "config.json"
          ''
            {
              "Port": ${toString config.services.asapo.authorizer-port},
              "LogLevel":"debug",
              "RootBeamtimesFolder":"${config.services.asapo.root-beamtimes-folder}",
              "CurrentBeamlinesFolder":"${config.services.asapo.current-beamlines-folder}",
              "AlwaysAllowedBeamtimes":[
                 {
                    "beamtimeId":"asapo_test",
                    "beamline":"test",
                    "corePath":"${config.services.asapo.root-beamtimes-folder}/asapo_test",
                    "beamline-path":"${config.services.asapo.current-beamlines-folder}"
                 }
              ],
              "UserSecretFile":"${secretKeyFile}",
              "AdminSecretFile":"${secretKeyFileAdmin}",
              "TokenDurationMin":600,
              "Ldap":
              {
                 "Uri" : "ldap://localhost:389",
                 "BaseDn" : "ou=rgy,o=desy,c=de",
                 "FilterTemplate" : "(cn=a3__BEAMLINE__-hosts)"
              },
              "DatabaseServer":"localhost:${toString config.services.asapo.mongo-port}",
              "DiscoveryServer": "0.0.0.0:${toString config.services.asapo.discovery-port}",
              "UpdateRevokedTokensIntervalSec": 60
            }

          '';
      in
      {
        description = "ASAP:O authorizer";
        after = [ "asapo-discovery.service" "mongodb.service" ];

        serviceConfig = {
          User = "asapo";
          Group = "asapo";
          ExecStartPre = pkgs.writeShellScript "authorizer-start-pre.sh" ''
            mkdir -p $(dirname ${config.services.asapo.tokens-path})
            ${pkgs.asapo-authorizer}/bin/authorizer -config ${configFile} create-token -access-types write,read,writeraw -beamline asapo_test -type user-token | ${pkgs.jq}/bin/jq .Token | sed -e 's/"//g' > "${config.services.asapo.tokens-path}"
          '';
          ExecStart = "${pkgs.asapo-authorizer}/bin/authorizer -config ${configFile}";
        };
      };

    systemd.services.asapo-receiver =
      let
        configFile = pkgs.writeText "config.json"
          ''
            {
              "MonitoringServer": "localhost:${toString config.services.asapo.monitoring-port}",
              "PerformanceDbServer":"localhost:${toString config.services.asapo.influxdb-port}",
              "MonitorPerformance": true,
              "PerformanceDbName": "db_test",
              "DatabaseServer":"localhost:${toString config.services.asapo.mongo-port}",
              "DiscoveryServer": "localhost:${toString config.services.asapo.discovery-port}",
              "DataServer": {
                "AdvertiseURI": "127.0.0.1:${toString config.services.asapo.receiver-advertiser-port}",
                "NThreads": 2,
                "ListenPort": ${toString config.services.asapo.receiver-advertiser-port},
                "NetworkMode": ["tcp"]
              },
              "Metrics": {
                "Expose": true,
                "ListenPort": ${toString config.services.asapo.receiver-metrics-port}
              },
              "DataCache": {
                "Use": true,
                "SizeMB": 100,
                "ReservedShare": 10
              },
              "AuthorizationServer": "localhost:${toString config.services.asapo.authorizer-port}",
              "AuthorizationInterval": 1000,
              "ListenPort": ${toString config.services.asapo.receiver-port},
              "Tag": "localhost",
              "ReceiveToDiskThresholdMB":50,
              "MaxNumPersistedStreams":100,
              "LogLevel" : "debug",
              "Kafka" : {
                "Enabled" : false
              }
              }
          '';
      in
      {
        description = "ASAP:O receiver";
        after = [ "network.target" "influxdb.service" ];
        wants = [ "asapo-create-influxdb-databases.service" ];

        serviceConfig = {
          User = "asapo";
          Group = "asapo";
          ExecStartPre = pkgs.writeShellScript "receiver-start-pre.sh" ''
            mkdir -p ${config.services.asapo.current-beamlines-folder}
          '';

          ExecStart = "${pkgs.asapo-libs}/bin/receiver ${configFile}";
        };
      };

    systemd.services.asapo-file-transfer =
      let
        secretKeyFile = pkgs.writeText "auth_secret.key" config.services.asapo.secret-key;
        configFile = pkgs.writeText "config.json"
          ''
            {
              "Port": ${toString config.services.asapo.file-transfer-port},
              "LogLevel":"debug",
              "SecretFile":"${secretKeyFile}",
              "DiscoveryServer": "localhost:${toString config.services.asapo.discovery-port}",
              "MonitorPerformance": true,
              "MonitoringServerUrl": "localhost:${toString config.services.asapo.monitoring-port}"
            }
          '';
      in
      {
        description = "ASAP:O file transfer";
        after = [ "network.target" "asapo-monitoring-server.service" ];

        serviceConfig = {
          User = "asapo";
          Group = "asapo";
          ExecStart = "${pkgs.asapo-file-transfer}/bin/file-transfer -config ${configFile}";
        };
      };

    systemd.targets.asapo = {
      description = "ASAP:O environment with all daemons";

      requires = [
        "asapo-discovery.service"
        "asapo-receiver.service"
        "asapo-broker.service"
        "asapo-authorizer.service"
        "asapo-file-transfer.service"
        "asapo-monitoring-server.service"
      ];
      after = [
        "asapo-discovery.service"
        "asapo-receiver.service"
        "asapo-broker.service"
        "asapo-authorizer.service"
        "asapo-file-transfer.service"
        "asapo-monitoring-server.service"
      ];

      wantedBy = [ "multi-user.target" ];
    };
  };
}
