let
  base = {
    kill_signal = "SIGINT";
    kill_timeout = 5;
    processes = [ ];
    services = [
      {
        internal_port = 8080;
        processes = [ "app" ];
        protocol = "tcp";
        concurrency = {
          hard_limit = 25;
          soft_limit = 20;
          type = "connections";
        };
        ports = [
          {
            handlers = [ "http" ];
            port = 80;
          }
          {
            handlers = [ "tls" "http" ];
            port = 443;
          }
        ];
        http_checks = [
          {
            grace_period = "1s";
            interval = "15s";
            timeout = "2s";
            path = "/";
            method = "get";
            protocol = "http";
          }
        ];
      }
    ];
  };
in
{
  production = base // {
    app = "nix-fly-template";
  };
  staging = base // {
    app = "nix-fly-template-staging";
  };
}
