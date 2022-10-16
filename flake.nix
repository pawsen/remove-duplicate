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
        python3 = pkgs.python3;

      in rec {  # rec allows to recursively resolve any nix variable
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            (python3.withPackages(ps: with ps; [
              ipython
              numpy
              pandas
              pillow
              # for developing/doom
              black     # format
              isort     # sort imports
              pyflakes  # check python files for error
            ]))
            nodePackages.pyright  # lsp server of choice

            # just for lol
            figlet
            lolcat

          ];
          # shellHook = "jupyter notebook";
          shellHook = ''
            figlet "Ready to python!" | lolcat --freq 0.5
            echo "using python version ${python3.name} which is located at ${python3}"
          '';

          # maybe not needed?
          PYTHONPATH = builtins.toPath ./.;
        };
      }
    );
}
