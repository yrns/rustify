{
  description = "a template for new rust projects";
  inputs = {};
  outputs = {self}: {
    lib.crateOverrides = {
      lockFile,
      pkgs,
    }: let
      inherit
        (builtins)
        listToAttrs
        fromTOML
        readFile
        intersectAttrs
        mapAttrs
        getAttr
        any
        attrValues
        hasAttr
        foldl'
        ;
      inherit (pkgs.lib) nameValuePair mergeAttrsWithFunc toList;
      overrides = with pkgs;
        defaultCrateOverrides
        // {
          alsa-sys = attrs: {buildInputs = [alsa-lib];};
          # This is probably redundant since stdenv includes gcc.
          cc = attrs: {nativeBuildInputs = [stdenv.cc];};
          # Via: rg cargo:rustc-link-lib=stdc++ $CARGO_TARGET_DIR/debug/build
          # Use "extraLinkFlags"?
          meshopt = attrs: {buildInputs = [stdenv.cc.cc.lib];};
          cmake = attrs: {buildInputs = [cmake];};
          expat-sys = attrs: {buildInputs = [expat];};
          freetype-sys = attrs: {buildInputs = [freetype];};
          glutin_egl_sys = attrs: {buildInputs = [libglvnd];};
          glutin_gles2_sys = attrs: {buildInputs = [libglvnd];};
          glutin_glx_sys = attrs: {buildInputs = [libglvnd];};
          glutin_wgl_sys = attrs: {buildInputs = [libglvnd];};
          khronos-egl = attrs: {buildInputs = [libglvnd];};
          pkg-config = attrs: {nativeBuildInputs = [pkg-config];};
          servo-fontconfig = attrs: {buildInputs = [fontconfig];};
          yeslogic-fontconfig-sys = attrs: {buildInputs = [fontconfig];};
          x11-dl = attrs: {
            buildInputs = with xorg; [
              libX11
              libXcursor
              libXrandr
              libXi
            ]; # libXrender?
          };
          ash = attrs: {
            buildInputs = [vulkan-headers vulkan-loader vulkan-validation-layers];
          };
          xcb = attrs: {buildInputs = [xorg.libxcb];};
          atk-sys = attrs: {buildInputs = [atk];};
          # Need to pick the right python...
          # pyo3-build-config = attrs: {
          #   buildInputs = [python3];
          #   shellHook = ''
          #     export PYO3_PYTHON="${python3}/bin/python"
          #   '';
          # };
          pango-sys = attrs: {buildInputs = [pango];};
          # libpng/libtiff depend on zlib. dbus-glib from the defaultCrateOverrides is being
          # overridden, but I'm not sure it's actually required...
          gdk-pixbuf-sys = attrs: {buildInputs = [gdk-pixbuf zlib];};
          gdk-sys = attrs: {buildInputs = [gtk3];};
          gio-sys = attrs: {buildInputs = [glib];};
          # TODO: This has been archived.
          glazier = attrs: {
            nativeBuildInputs = [clang llvmPackages.libclang];
            buildInputs = [libxkbcommon];
            shellHook = ''
              export LIBCLANG_PATH="${llvmPackages.libclang.lib}/lib"
            '';
          };
          gobject-sys = attrs: {buildInputs = [gobject-introspection];};
          # GTK may have some transitive dependencies not included here. The rfd crate requires harfbuzz:
          gtk-sys = attrs: {
            buildInputs = [gtk3 harfbuzz];
            # https://nixos.wiki/wiki/Development_environment_with_nix-shell#No_GSettings_schemas_are_installed_on_the_system
            shellHook = ''
              export XDG_DATA_DIRS=$GSETTINGS_SCHEMAS_PATH:$XDG_DATA_DIRS
            '';
          };
          input-sys = attrs: {buildInputs = [libinput];};
          rusqlite = attrs: {buildInputs = [sqlite];};
          libaom-sys = attrs: {buildInputs = [libaom nasm];};
          libudev-sys = attrs: {buildInputs = [udev];};
          wayland-sys = attrs: {buildInputs = [wayland];};
          smithay-client-toolkit = attrs: {buildInputs = [libxkbcommon];};
          openssl-sys = attrs: {buildInputs = [openssl];};
          sndfile-sys = attrs: {buildInputs = [libsndfile];};
          evil-janet = attrs: {
            # clang stuff needed for the "amalgation" feature:
            nativeBuildInputs = [clang llvmPackages.libclang];
            # and for "system" or "link-system"...
            buildInputs = [janet];

            shellHook = ''
              export LIBCLANG_PATH="${llvmPackages.libclang.lib}/lib"
              export JANET_HEADERPATH="${janet}/include"
            '';
          };
          xkbcommon-dl = attrs: {buildInputs = [libxkbcommon];};
        };
      # listToAttrs requires { name = ..., value = ... }
      packages =
        listToAttrs (map (p: (nameValuePair p.name p))
          (fromTOML (readFile lockFile)).package);
      mapIntersectAttrs = f: a: b:
        mapAttrs (n: b': (f (getAttr n a) b')) (intersectAttrs a b);
      overrides' = mapIntersectAttrs (attrs: f: (f attrs)) packages overrides;
      # does not work for packages
      #unique = foldl' (acc: e: if (any (e': e' == e) acc) then acc else acc ++ [ e ]) [];
      merge = mergeAttrsWithFunc (a: b: (toList a) ++ (toList b));
      attrs = foldl' merge {} (attrValues overrides');
      # flatten shellHooks:
    in
      mapAttrs
      (k: v:
        if (k == "shellHook")
        then builtins.concatStringsSep "\n" v
        else v)
      attrs;

    lib.mkShell = {
      lockFile,
      pkgs,
    }: let
      inputs = self.lib.crateOverrides {inherit lockFile pkgs;};
      inherit (pkgs) lib;
    in
      pkgs.mkShell {
        inputsFrom = [inputs];
        # export LD_LIBRARY_PATH="${lib.makeLibraryPath inputs.buildInputs}"

        # Alternatively, do this above for specific crates that dlopen (e.g. xkbcommon-dl)?
        shellHook = ''
          export NIX_LDFLAGS="-rpath ${lib.makeLibraryPath inputs.buildInputs}";
        '';
      };

    defaultTemplate = {
      path = ./template;
      description = "nix flake new -t github:yrns/rustify .";
    };
  };
}
