{
  description = "merl-an Nix Flake";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.cb-repository = {
    url = "github:ocurrent/current-bench";
    flake = false;
  };


  outputs = { self, nixpkgs, flake-utils, cb-repository }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs.ocamlPackages) buildDunePackage;
        cb-check = buildDunePackage {
          pname = "cb-check";
          src = cb-repository;
          version = "n/a";
          duneVersion = "3";
          buildInputs = with pkgs.ocamlPackages; [
            ocaml
            yojson
          ];
        };
      in
        rec {
          packages = rec {
            default = merl-an;
            merl-an = buildDunePackage {
              pname = "merl-an";
              version = "n/a";
              src = ./.;
              duneVersion = "3";
              nativeBuildInputs = [
                pkgs.jq
                pkgs.ocamlPackages.merlin
                cb-check
              ];
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
                ];
              doCheck = true;
            };
          };
          devShells.default = pkgs.mkShell {
            inputsFrom = pkgs.lib.attrValues packages;
            buildInputs = with pkgs.ocamlPackages; [
              pkgs.ocamlformat_0_24_1
              cb-check
              ocaml-lsp
              pkgs.jq
            ];
          };
        });
}
