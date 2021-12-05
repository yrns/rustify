{
  description = "?";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.utils.url = "github:numtide/flake-utils";
  #inputs.rustify.url = "github:yrns/rustify";
  inputs.rustify.url = "path:/home/al/src/rustify";

  outputs = { self, nixpkgs, utils, rustify }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        crates = (rustify.lib.lockFile {
          lockFile = ./Cargo.lock;
        });
      in
      {
        devShell = pkgs.mkShell
          {
            nativeBuildInputs = [ pkgs.bashInteractive ];
            buildInputs = [ ];
          };
      });
}
