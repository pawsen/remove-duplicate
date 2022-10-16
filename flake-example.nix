# https://dev.to/deciduously/workspace-management-with-nix-flakes-jupyter-notebook-example-2kke

# advanced example, using pre-commit-hooks, etc
# https://github.com/cpcloud/stupidb/blob/main/flake.nix

# also followed these articles
# https://github.com/samdroid-apps/nix-articles

{
  description = "A basic flake for python. nix develop ";
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/master";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-utils.url = "github:numtide/flake-utils";

    # flake-utils = {
    #   url = "github:numtide/flake-utils";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        python3 = pkgs.python3;


          # Here we define our function to "lolcatify" a program.
          # It takes 2 arguments, the `package` of the app
          # and the `name` of original name the binary.
          # It accepts other arguments or the lolcat command
          #
          # functions in nix only takes one input. So for multiple inputs we use closure
          # we have a function that takes the first argument, then returns another function.
          # nix evaluates from inner-most parenthesis and outward
          # the parenthesis are not needed - only added for readability
          # lolcatify = package : (name : (pkgs.writeShellScriptBin "lol-${name}" ''COMMAND''));
          lolcatify = {
            name,
              # ? denotes default values
              package ? pkgs.coreutils,
              # Nix does not have floating point or decimal numbers
              frequency ? "0.1",
              spread ? "3.0",
              seed ? "0",
          } : let
            # Using a let-in clause is allowed in a function
            # remember is is just an expression after all
            lolcatArgs = "--freq ${frequency} --spread ${spread} --seed ${seed}";
          in
            pkgs.writeShellScriptBin "lol-${name}" ''
          # shell script to pass all argument to the original command,
          # and pass output to lolcat
          ${package}/bin/${name} "$@" | ${pkgs.lolcat}/bin/lolcat ${lolcatArgs}
        '';

            in rec {  # rec allows to recursively resolve any nix variable

              lol-env = pkgs.stdenv.mkDerivation {
                name = "lol-environment";

                buildInputs = [
                  (lolcatify { name = "figlet"; package = pkgs.figlet; })
                  # Changing the optional freq argument
                  (lolcatify { name = "cowsay"; package = pkgs.cowsay; frequency = "0.5"; })

                  # These use the default value for the package argument
                  (lolcatify { name = "cat"; })
                  (lolcatify { name = "seq"; })
                ];
              };

              # devShell.default = pkgs.mkShell {
              # devShell = pkgs.mkShell {
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

                  # We must use parenthesis to avoid confusing between
                  # a function call (what we want) and list items (which are
                  # also space separated)
                  (lolcatify { name = "figlet"; package = pkgs.figlet;})
                  (lolcatify { package = pkgs.cowsay; name = "cowsay"; frequency = "0.5";})
                ];
                # shellHook = "jupyter notebook";
                shellHook = ''
            figlet "Ready to python!" | lolcat --freq 0.5
            echo "using python version ${python3.name} which is located at ${python3}"
          '';

                # maybe not needed?
                PYTHONPATH = builtins.toPath ./.;
              };

              defaultApp = flake-utils.lib.mkApp {
                drv = lol-env;
              };

              # packages = {
              #   lol-env = lol-env;
              # };

              # # package
              # # https://python.on-nix.com/projects/poetry-latest-python39/
              # packages = {
              #   lolify = stdenv.mkDerivation {
              #     name = "lolify";
              #     (lolcatify { name = "figlet"; package = pkgs.figlet;})
              #       (lolcatify { package = pkgs.cowsay; name = "cowsay"; frequency = "0.5";})

              #   };
              # };
            }
          );
    }
