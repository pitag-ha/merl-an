{
  description = "merl-an Nix Flake";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs.ocamlPackages) buildDunePackage;
      in
        rec {
          packages = rec {
            default = merl-an;
            merl-an = buildDunePackage {
              pname = "merl-an";
              version = "n/a";
              src = ./.;
              duneVersion = "3";
              buildInputs = with pkgs.ocamlPackages;
                [
                    ocaml
                    ppxlib
                    yojson
                    fpath
                    bos
                    cmdliner
                    ppx_deriving_yojson
                    ppx_enumerate
                    ppx_fields_conv
                    ppx_yojson_conv
                    ptime
                ];
              checkInputs = with pkgs.ocamlPackages;
                [ merlin
                  pkgs.jq
                ];
              doCheck = true;
            };
          };
          devShells.default = pkgs.mkShell {
            inputsFrom = pkgs.lib.attrValues packages;
            buildInputs = with pkgs.ocamlPackages; [ merlin ];
          };
        });
}
