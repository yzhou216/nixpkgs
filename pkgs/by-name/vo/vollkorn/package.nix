{
  fetchzip,
  installFonts,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "vollkorn";
  version = "4.105";

  src = fetchzip {
    url = "http://vollkorn-typeface.com/download/vollkorn-${
      builtins.replaceStrings [ "." ] [ "-" ] finalAttrs.version
    }.zip";
    stripRoot = false;
    hash = "sha256-oG79GgCwCavbMFAPakza08IPmt13Gwujrkc/NKTai7g=";
  };

  nativeBuildInputs = [ installFonts ];

  installPhase = ''
    runHook preInstall

    install -Dm644 WOFF/*.woff --target-directory=$out/share/fonts/WOFF
    install -Dm644 WOFF2/*.woff2 --target-directory=$out/share/fonts/WOFF2
    install -Dm644 {Fontlog,OFL-FAQ,OFL}.txt \
      --target-directory=$out/share/doc/${finalAttrs.pname}-${finalAttrs.version}

    runHook postInstall
  '';

  meta = {
    description = "Free and healthy typeface for bread and butter use";
    homepage = "http://vollkorn-typeface.com";
    license = lib.licenses.ofl;
    maintainers = [ lib.maintainers.schmittlauch ];
    platforms = lib.platforms.all;
  };
})
