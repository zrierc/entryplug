# Lilex patched with Nerd Fonts glyphs, built from the upstream release rather
# than nixpkgs' nerd-fonts.lilex: that bundle carries Lilex 2.700 (2026-04-04),
# upstream 2.630 is from 2026-10-05. Lilex's version numbers are not monotonic,
# so compare release dates, not tags.
{ fetchurl, nerd-font-patcher, runCommand, unzip }:

let
  version = "2.630";

  # All 14 static styles, patched with --mono (single-width glyphs), which is
  # the variant a terminal wants. The Nerd Fonts archive for Lilex ships 10
  # styles and skips Light and SemiBold.
  # Add --adjust-line-height if the icons sit badly against the line height.
in
runCommand "lilex-nerd-font-mono-${version}" {
  nativeBuildInputs = [ nerd-font-patcher unzip ];
} ''
  mkdir -p src

  unzip -j ${fetchurl {
    url = "https://github.com/mishamyrt/Lilex/releases/download/${version}/Lilex.zip";
    hash = "sha256-yUa/Ai8iiVeZ62m8xfIxjtQInk40uQBU39eO1TFnKOA=";
  }} 'ttf/*.ttf' -d src

  mkdir -p $out/share/fonts/truetype
  for font in src/*.ttf; do
    nerd-font-patcher --quiet --mono --outputdir $out/share/fonts/truetype "$font"
  done
''
