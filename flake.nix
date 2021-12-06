{
  description = "a template for new rust projects";
  inputs = {};
  outputs = { self }: {    
    lib.crateOverrides = { lockFile, pkgs }:
      let
        inherit (builtins) listToAttrs fromTOML readFile intersectAttrs mapAttrs getAttr any attrValues hasAttr foldl';
        inherit (pkgs.lib) nameValuePair mergeAttrsWithFunc toList;
        overrides = with pkgs; defaultCrateOverrides // {
          alsa-sys = attrs: {
            buildInputs = [ alsaLib ];
          };
          pkg-config = attrs: {
            nativeBuildInputs = [ pkg-config ];
          };
          x11-dl = attrs: {
            buildInputs = with xorg; [
              libX11 libXcursor libXrandr libXi ]; # libXrender?
          };
          ash = attrs: {
             buildInputs = [ vulkan-headers vulkan-loader vulkan-validation-layers ];
          };
          xcb = attrs: {
            buildInputs = [ xorg.libxcb ];
          };
        };
        # listToAttrs requires { name = ..., value = ... }
        packages = listToAttrs (map (p: (nameValuePair p.name p)) (fromTOML (readFile lockFile)).package);
        mapIntersectAttrs = f: a: b: mapAttrs (n: b': (f (getAttr n a) b')) (intersectAttrs a b);
        overrides' = mapIntersectAttrs (attrs: f: (f attrs)) packages overrides;
        # does not work for packages
        #unique = foldl' (acc: e: if (any (e': e' == e) acc) then acc else acc ++ [ e ]) [];
        merge = mergeAttrsWithFunc (a: b: (toList a) ++ (toList b));
      in
        foldl' merge {} (attrValues overrides');
    
    defaultTemplate = {
        path = ./template;
        description = "nix flake new -t github:yrns/rustify .";
      };
  };
}
