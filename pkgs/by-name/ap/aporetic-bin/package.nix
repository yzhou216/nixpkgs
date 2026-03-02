{
  fetchFromGitHub,
  installFonts,
  lib,
  nix-update-script,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "aporetic-bin";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "protesilaos";
    repo = "aporetic";
    tag = finalAttrs.version;
    hash = "sha256-1BbuC/mWEcXJxzDppvsukhNtdOLz0QosD6QqI/93Khc=";
  };

  nativeBuildInputs = [ installFonts ];

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://github.com/protesilaos/aporetic";
    description = "Aporetic fonts";
    longDescription = ''
      Aporetic is the successor to Iosevka Comfy, customised build of
      the [Iosevka typeface](https://github.com/be5invis/Iosevka),
      with a consistent rounded style and overrides for almost all
      individual glyphs in both upright (roman) and slanted (italic)
      variants.
    '';
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ DamienCassou ];
  };
})
