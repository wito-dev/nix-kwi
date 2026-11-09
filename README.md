# nix-kwi

Nix flake for [Kwi](https://invent.kde.org/utilities/kwi), the KDE terminal
emulator built on Ghostty's `libghostty-vt`.

Kwi has no tagged release yet, so this flake builds upstream `master`. A GitHub
Actions job refreshes the pin every day and pushes a new `flake.lock` only when
the build passes.

## Run it

```sh
nix run github:wito-dev/nix-kwi
```

## Use it as an input

```nix
{
  inputs.kwi = {
    url = "github:wito-dev/nix-kwi";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Then either take the package:

```nix
inputs.kwi.packages.${system}.default
```

or the overlay, which adds `pkgs.kwi` and the matching `pkgs.libghostty-vt`:

```nix
nixpkgs.overlays = [ inputs.kwi.overlays.default ];
```

## libghostty-vt

`libghostty-vt` is released separately from the Ghostty app and has its own
version numbers. nixpkgs lags behind, so the flake builds the exact release
that Kwi pins in its own Flatpak manifest. Bumping `kwi-src` therefore also
follows upstream's library bumps, and the same manifest supplies the Zig
version the build needs.

## Update manually

```sh
nix flake update kwi-src
nix build
```
