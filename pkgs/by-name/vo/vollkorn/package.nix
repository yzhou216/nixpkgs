{
  lib,
  stdenvNoCC,
  fetchzip,
  installFonts,
}:

stdenvNoCC.mkDerivation rec {
  pname = "vollkorn";
  version = "4.105";

  src = fetchzip {
    url = "http://vollkorn-typeface.com/download/vollkorn-${
      builtins.replaceStrings [ "." ] [ "-" ] version
    }.zip";
    stripRoot = false;
    hash = "sha256-oG79GgCwCavbMFAPakza08IPmt13Gwujrkc/NKTai7g=";
  };

  nativeBuildInputs = [ installFonts ];

  installPhase = ''
    runHook preInstall

    mkdir -pv $out/share/{doc/${pname}-${version},fonts/{opentype,truetype,WOFF,WOFF2}}
    cp -v {Fontlog,OFL-FAQ,OFL}.txt $out/share/doc/${pname}-${version}/
    cp -v WOFF/*.woff $out/share/fonts/WOFF
    cp -v WOFF2/*.woff2 $out/share/fonts/WOFF2

    runHook postInstall
  '';

  meta = {
    homepage = "http://vollkorn-typeface.com/";
    description = "Free and healthy typeface for bread and butter use";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
    maintainers = [ lib.maintainers.schmittlauch ];
  };
}
