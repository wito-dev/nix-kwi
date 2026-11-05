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

Kwi needs `libghostty-vt` 1.4.0 or newer. nixpkgs still ships an older Ghostty
snapshot of that library, so the flake rebuilds the library from the Ghostty
release that nixpkgs already packages. The build needs Zig 0.17, which is why
the override replaces the Zig version that nixpkgs' `libghostty-vt` uses.

## Update manually

```sh
nix flake update kwi-src
nix build
```
