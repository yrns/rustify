{
  description = "a template for new rust projects";
  inputs = {};
  outputs = { self }: {    
    lib.crateOverrides = { lockFile, pkgs }:
      let
        inherit (builtins) fromTOML readFile hasAttr foldl';
        overrides = with pkgs; defaultCrateOverrides // {
          # Cargo.lock is only valid for the current system, which we
          # can't check in a flake, so we have to handle platform for
          # each crate here.
          alsa-sys = attrs: {
            buildInputs = lib.optionals (!stdenv.isDarwin) [ alsaLib ];
          };
          pkg-config = attrs: {
            nativeBuildInputs = [ pkg-config ];
          };
        };
        packages = (fromTOML (readFile lockFile)).package;
        checkOverride = attrs:
          let name = attrs.name; in
          if hasAttr name overrides then
            builtins.trace "got: ${name}"
            overrides.${name} attrs
          else
            {};
        overrides' = map checkOverride packages;     
      in        
        builtins.trace (builtins.toJSON overrides') foldl' pkgs.lib.mergeAttrsConcatenateValues {} overrides';
    
    defaultTemplate = {
        path = ./template;
        description = "nix flake new -t github:yrns/rustify .";
      };
  };
}
