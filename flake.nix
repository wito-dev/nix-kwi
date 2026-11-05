{
  description = "Nix flake for Kwi, the KDE terminal emulator built on libghostty-vt";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # Kwi has no tagged release yet, so the flake builds upstream master.
  # .github/workflows/update.yml bumps this pin every day.
  inputs.kwi-src = {
    url = "git+https://invent.kde.org/utilities/kwi.git";
    flake = false;
  };

  outputs =
    { self, nixpkgs, kwi-src }:
    let
      systems = [ "x86_64-linux" ];

      # Kwi needs libghostty-vt 1.4.0 or newer, but nixpkgs still pins the
      # library to an older Ghostty snapshot. Rebuild the VT library from the
      # Ghostty release that nixpkgs packages, with the Zig version that
      # Ghostty 1.4.0 requires.
      overrideLibghosttyVt =
        pkgs:
        pkgs.libghostty-vt.overrideAttrs (old: {
          version = pkgs.ghostty.version;
          src = pkgs.ghostty.src;
          deps = pkgs.ghostty.deps;
          nativeBuildInputs = map (
            pkg: if (pkg.pname or null) == "zig" then pkgs.zig_0_17 else pkg
          ) old.nativeBuildInputs;
        });

      # Kwi has no release tags yet, so read the CMake project version and mark
      # the build as unstable.
      version =
        let
          lines = nixpkgs.lib.splitString "\n" (builtins.readFile "${kwi-src}/CMakeLists.txt");
          line = nixpkgs.lib.findFirst (l: nixpkgs.lib.hasPrefix "project(kwi VERSION " l) "" lines;
        in
        if line == "" then
          "0-unstable"
        else
          let
            words = builtins.filter (w: w != "") (
              nixpkgs.lib.splitString " " (nixpkgs.lib.removePrefix "project(kwi VERSION " line)
            );
          in
          "${nixpkgs.lib.head words}-unstable";

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (pkgsFor system));
    in
    {
      overlays.default =
        final: prev:
        let
          libghostty-vt = overrideLibghosttyVt prev;
        in
        {
          inherit libghostty-vt;
          kwi = final.callPackage ./package.nix {
            inherit version;
            src = kwi-src;
          };
        };

      packages = forAllSystems (pkgs: {
        default = pkgs.kwi;
        inherit (pkgs) kwi libghostty-vt;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ pkgs.kwi ];
        };
      });
    };
}
