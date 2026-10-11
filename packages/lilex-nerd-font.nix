# upstream 2.630; nixpkgs' nerd-fonts bundle ships an older Lilex
{ fetchurl, nerd-font-patcher, runCommand, unzip }:

let
  version = "2.630";

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
