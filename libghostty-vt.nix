# Build libghostty-vt from the release that Kwi pins in its Flatpak manifest.
#
# libghostty-vt is released separately from the Ghostty app and has its own
# version numbers. nixpkgs lags behind, so the input that Kwi actually builds
# and tests against is the authoritative one. Reading Kwi's manifest keeps the
# daily update job working when upstream bumps the library.
{
  lib,
  stdenv,
  fetchurl,
  pkgs,
  kwiSrc,
}:

let
  manifest = builtins.fromJSON (builtins.readFile "${kwiSrc}/.flatpak-manifest.json");

  module = lib.findFirst (
    m: m.name == "libghostty-vt"
  ) (throw "Kwi's Flatpak manifest has no libghostty-vt module") manifest.modules;

  archives = lib.filter (source: source.type == "archive") module.sources;

  sourceArchive = lib.findFirst (
    source: lib.hasInfix "/libghostty-vt/" source.url && !(lib.hasInfix "-deps" source.url)
  ) (throw "Kwi's Flatpak manifest has no libghostty-vt source tarball") archives;

  depsSource = lib.findFirst (
    source: lib.hasInfix "libghostty-vt-" source.url && lib.hasInfix "-deps.tar.gz" source.url
  ) (throw "Kwi's Flatpak manifest has no libghostty-vt dependency tarball") archives;

  version = builtins.head (builtins.match ".*/libghostty-vt/([^/]+)/.*" sourceArchive.url);

  # The manifest also pins the Zig toolchain the library must be built with.
  zigVersion = builtins.head (
    builtins.match ".*/zig-x86_64-linux-([0-9.]+)\\.tar\\.xz"
      (lib.findFirst (
        source: lib.hasInfix "/zig-x86_64-linux-" source.url
      ) (throw "Kwi's Flatpak manifest has no x86_64 Zig tarball") module.sources).url
  );

  zig = pkgs."zig_${lib.replaceStrings [ "." ] [ "_" ] (lib.versions.majorMinor zigVersion)}";

  src = fetchurl {
    url = sourceArchive.url;
    sha256 = sourceArchive.sha256;
  };

  # The dependency tarball unpacks to the exact package-cache layout that Zig
  # reads through `--system`, so the build needs no network access.
  depsArchive = fetchurl {
    url = depsSource.url;
    sha256 = depsSource.sha256;
  };

  deps = pkgs.runCommand "libghostty-vt-${version}-deps" { } ''
    mkdir -p $out
    tar -xzf ${depsArchive} --strip-components=1 -C $out
  '';
in
stdenv.mkDerivation {
  pname = "libghostty-vt";
  inherit version src;

  nativeBuildInputs = [ zig ];

  dontSetZigDefaultFlags = true;

  zigBuildFlags = [
    "--system"
    "${deps}"
    "-Doptimize=ReleaseFast"
    "-Dcpu=baseline"
  ];

  doCheck = false;

  meta = {
    description = "Ghostty VT library, built from the release Kwi pins";
    homepage = "https://ghostty.org";
    license = lib.licenses.mit;
    platforms = zig.meta.platforms;
  };
}
