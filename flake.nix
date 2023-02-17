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

            default = dummy;

            # Dummy package to test our Nix setup works
            dummy = pkgs.dockerTools.buildImage {
                name = "dummy";
                tag = "local";

                # Not strictly necessary but nice for debugging
                copyToRoot = with pkgs; [
                    coreutils
                    dockerTools.usrBinEnv
                    dockerTools.binSh
                ];

                runAsRoot = ''
                    #!/bin/sh
                    ${pkgs.dockerTools.shadowSetup}
                '';

                config = {
                    Entrypoint = [ "/bin/sh" "-c" ];
                };
            };
    
            img-nix-serve = pkgs.dockerTools.buildImage {
                name = "nix-serve";
                tag = "local";

                # fromImage = nixFromDockerHub;

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

# 9s0anw8p39klh6p8v0g21qf3c21xqnib-nix-serve-0.2-e4675e3
# mzm0x1j58m0ldfrxwgj1kdp6yibiz46w-nix-serve-0.2-e4675e3