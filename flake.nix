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
    {
      self,
      nixpkgs,
      kwi-src,
    }:
    let
      systems = [ "x86_64-linux" ];

      kwiSrc = kwi-src;

      # Kwi tracks libghostty-vt independently of the Ghostty app, and nixpkgs
      # lags behind both. Build the library release that Kwi pins in its
      # Flatpak manifest instead of reusing nixpkgs' snapshot.
      libghosttyVt = pkgs: pkgs.callPackage ./libghostty-vt.nix { inherit kwiSrc pkgs; };

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
          libghostty-vt = libghosttyVt prev;
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
