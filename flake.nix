{
  description = "Matsuri dev environment";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-26.05"; # Or a specific stable channel like "nixos-24.05"
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # overlays = [ ];
        };
      in
        with pkgs; {
          devShell = mkShell {
            buildInputs = [
              ruby_4_0
            ];
          };
    });
}
