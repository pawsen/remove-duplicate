# https://dev.to/deciduously/workspace-management-with-nix-flakes-jupyter-notebook-example-2kke

{
  description = "A basic flake for python. nix develop ";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        python = pkgs.python3;
        pythonPackages = python.pkgs;

        # python runtime dependencies
        buildEnv = python.withPackages (ps: with ps; [
          pillow
        ]);

        # python Dev dependencies  -- not really, just for future ref.
        devEnv = python.withPackages (ps: with ps; [
          black
          debugpy
          ipython
          isort
          # pytest
        ]);

        devInputs = with pkgs; [
          devEnv
          # binaries
          findimagedupes
          nodePackages.pyright  # lsp server of choice
        ];
        buildInputs = with pkgs; [
          buildEnv

        ];
        defaultPackage = pkgs.stdenvNoCC.mkDerivation {

          # the name(or pname) must mach the name of the binary for `nix run`,
          # unless a specific path is given by `program = "${defaultPackage}/bin/mybin"`
          name = "remove duplicate images";
          pname = "remove-duplicates";
          buildInputs = [
          ]++buildInputs;
          # set unpack to /bin/true, ie. don't unpack
          unpackPhase = "true";
          installPhase = ''
            mkdir -p $out/bin
            cp ${./remove-duplicates.py} $out/bin/remove-duplicates
            chmod +x $out/bin/remove-duplicates
          '';
        };

      in rec {  # rec allows to recursively resolve any nix variable

        # packages is used by `nix shell`
        # inherit defaultPackage;
        # instead of defaultPackage, we now need packages.default?
        packages = {
          remove-duplicates = defaultPackage;
          findimagedupes = pkgs.findimagedupes;
          # symlinkJoin is used to symlink binaries from a common `result/bin/`
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/trivial-builders.nix#L425
          all = pkgs.symlinkJoin {
            name = "findimagedupes and remove-duplicates";
            paths = [
              packages.remove-duplicates
              packages.findimagedupes
            ];
          };
          default = packages.all;
        };

        # apps is used by `nix run`
        # from https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-run.html#apps
        # apps.x86_64-linux.default = {
        #   type = "app";
        #   # program = defaultPackage;
        #   # manually specify the path to the executable
        #   program = "${defaultPackage}/bin/remove-duplicate";
        # };
        apps = {
          default = flake-utils.lib.mkApp {
            drv = defaultPackage;
          };
        };

        # devShell is used by `nix develop`
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            defaultPackage

            # just for lol
            figlet
            lolcat
          ]++ buildInputs ++devInputs;

          shellHook = ''
            figlet "Ready to python!" | lolcat --freq 0.5
            echo "using python version ${python.name} which is located at ${python}"
          '';

        };
      }
    );
}
