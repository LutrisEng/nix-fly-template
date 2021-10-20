# This is where you define the derivation for your app.
# For this example, we'll build a basic website using nginx.
# Based on https://github.com/NixOS/nixpkgs/blob/5f33ded6018c9bd2e203cd6d7bad4d6a62e46c2f/pkgs/build-support/docker/examples.nix#L44
{ stdenv, pandoc, writeText, writeShellScriptBin, nginx }:
let
  root = stdenv.mkDerivation {
    name = "app-static";
    src = ./.;
    buildInputs = [
      pandoc
    ];
    buildPhase = ''
      mkdir root
      pandoc README.md README.yaml -s -o root/index.html
    '';
    installPhase = ''
      mkdir $out
      cp -R root/* $out/
    '';
  };
  conf = writeText "nginx.conf" ''
    user nobody nobody;
    daemon off;
    error_log /dev/stdout info;
    pid /dev/null;
    events {}
    http {
      access_log /dev/stdout;
      server {
        listen 8080;
        index index.html;
        add_header X-Root-Path ${root};
        location / {
          root ${root};
        }
      }
    }
  '';
in
writeShellScriptBin "app" ''
  echo Starting nginx
  ${nginx}/bin/nginx -c ${conf}
  echo nginx exited with code $?
  exit $?
''
