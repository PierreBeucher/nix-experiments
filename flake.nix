{
  description = "Example Flake using Novops";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs?ref=nixpkgs-unstable;
    novops.url = "github:novadiscovery/novops";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, novops, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system};
        novopsPackage = novops.packages.${system}.novops;

        # nix-server has a bug with nix::initNix() 
        # See https://github.com/NixOS/nix/issues/7704
        nix-serve-override = pkgs.nix-serve.override {
            nix = pkgs.nixVersions.nix_2_12;
        };
      in {
        
        packages = rec {

            default = hello;

            hello = pkgs.hello;
            
            img-nix-serve = pkgs.dockerTools.buildImage {
                name = "nix-serve";
                tag = "local";


                # Not strictly necessary but nice for debugging
                copyToRoot = with pkgs; [
                    # nix
                    coreutils
                    gnugrep
                    dockerTools.usrBinEnv
                    dockerTools.binSh
                ];

                runAsRoot = ''
                    #!/bin/sh
                    ${pkgs.dockerTools.shadowSetup}
                '';

                config = {
                    Entrypoint = [ "${nix-serve-override}/bin/nix-serve" ];
                };
            };
        };

        devShells = {
          default = pkgs.mkShell {
            packages = [ 
              novopsPackage
            ];
            shellHook = ''
              novops load -s .envrc
              source .envrc
            '';
          };
        };
      }
    );    
}