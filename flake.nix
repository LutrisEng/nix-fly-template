{
  description = "A template for building and deploying applications on fly.com";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    rec {
      packages.app = pkgs.callPackage ./app.nix { };
      defaultPackage = packages.app;

      flyConfigs = import ./fly.nix;

      apps =
        let
          deployers = nixpkgs.lib.mapAttrs'
            (name: config:
              nixpkgs.lib.nameValuePair "deploy-${name}"
                (flake-utils.lib.mkApp {
                  drv = pkgs.writeShellScriptBin "deploy-${name}" ''
                    set -euxo pipefail
                    export PATH="${nixpkgs.lib.makeBinPath [(pkgs.docker.override { clientOnly = true; }) pkgs.flyctl]}:$PATH"
                    archive=${self.defaultDockerContainer.x86_64-linux}
                    config=${(pkgs.formats.toml {}).generate "fly.toml" config}

                    image=$(docker load < $archive | awk '{ print $3; }')
                    flyctl deploy -c $config -i $image
                  '';
                }))
            flyConfigs;
        in
        {
          app = flake-utils.lib.mkApp {
            drv = packages.app;
          };
        } // deployers;
      defaultApp = apps.app;

      # Adjust this to make sense for your app
      # Based on https://github.com/NixOS/nixpkgs/blob/5f33ded6018c9bd2e203cd6d7bad4d6a62e46c2f/pkgs/build-support/docker/examples.nix#L44
      dockerContainers.app = pkgs.dockerTools.buildLayeredImage {
        name = "app";
        contents = [
          pkgs.dockerTools.fakeNss
          packages.app
        ];
        extraCommands = ''
          mkdir -p var/{log,cache}/nginx
        '';
        config = {
          Cmd = [ apps.app.program ];
          ExposedPorts = {
            "8080/tcp" = { };
          };
        };
      };
      defaultDockerContainer = dockerContainers.app;

      devShell = pkgs.mkShell {
        buildInputs = [
          pkgs.flyctl
          pkgs.pandoc
        ];
      };

      hydraJobs = {
        inherit dockerContainers packages;
      };
    });
}
