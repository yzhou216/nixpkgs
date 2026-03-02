{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  installFonts,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "libre-franklin";
  version = "1.014";

  src = fetchFromGitHub {
    owner = "impallari";
    repo = "Libre-Franklin";
    rev = "006293f34c47bd752fdcf91807510bc3f91a0bd3";
    hash = "sha256-GR1KHiQ1lTOmU8eAPR2pxUlMpWiW2EDMG78VDjELxDU=";
  };

  nativeBuildInputs = [ installFonts ];

  installPhase = ''
    runHook preInstall

    install -Dm644 {README.md,FONTLOG.txt} \
      --target-directory=$out/share/doc/${finalAttrs.pname}-${finalAttrs.version}

    runHook postInstall
  '';

  meta = {
    description = "Reinterpretation and expansion based on the 1912 Morris Fuller Benton’s classic";
    homepage = "https://github.com/impallari/Libre-Franklin";
    license = lib.licenses.ofl;
    maintainers = [ ];
    platforms = lib.platforms.all;
  };
})
