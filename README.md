# nix-kwi

Nix flake for [Kwi](https://invent.kde.org/utilities/kwi), the KDE terminal
emulator built on Ghostty's `libghostty-vt`.

Kwi has no tagged release, so this flake builds upstream `master`. A scheduled
workflow refreshes the pin after the build passes.

## Build

Requires Nix with flakes enabled on `x86_64-linux`.

```sh
nix build github:wito-dev/nix-kwi
```

The build produces `result/bin/kwi`. Run it from a graphical KDE or Qt session.

## Use as a flake input

```nix
{
  inputs.kwi.url = "github:wito-dev/nix-kwi";
}
```

Take the package:

```nix
inputs.kwi.packages.${system}.default
```

Or use the overlay, which adds `pkgs.kwi` and `pkgs.libghostty-vt`:

```nix
nixpkgs.overlays = [ inputs.kwi.overlays.default ];
```

## Use the FlakeHub Cache

The CI workflows populate [FlakeHub Cache](https://flakehub.com/cache) when
the repository's FlakeHub account has FlakeHub Cache enabled. Nix selects
cache entries by store path, so the input can stay on GitHub.

FlakeHub Cache is a paid FlakeHub feature, and cache reads require
authentication. Repository maintainers must enable FlakeHub Cache for
`wito/nix-kwi` on a paid plan. Without it, the workflows fall back to the
GitHub Actions cache, which only serves those workflow runs.

1. Install [Determinate Nix](https://docs.determinate.systems/getting-started/individuals/)
   and log in:

   ```sh
   determinate-nixd login
   ```

2. Keep the input pointing at this repository:

   ```nix
   inputs.kwi.url = "github:wito-dev/nix-kwi";
   ```

3. Use the flake's locked inputs. A cache hit requires the same store paths:

   ```nix
   # Do not add this if you want cache hits: it replaces the locked nixpkgs.
   # inputs.kwi.inputs.nixpkgs.follows = "nixpkgs";
   ```

   If your `flake.lock` resolves `nixpkgs` or `kwi-src` to a different
   revision than this flake's lock, the store paths differ and the cache
   misses. The cache only contains revisions that CI built.

With FlakeHub Cache enabled, Determinate Nix authenticates on GitHub Actions
automatically. Add `id-token: write` to the job and use the
[`flakehub-cache-action`](https://github.com/DeterminateSystems/flakehub-cache-action).

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

## License

Kwi is licensed under `GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL`.
See the [upstream project](https://invent.kde.org/utilities/kwi) for details.
