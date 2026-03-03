{
  fetchurl,
  installFonts,
  lib,
  p7zip,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rounded-mgenplus";
  version = "20150602";

  src = fetchurl {
    url = "https://osdn.jp/downloads/users/8/8598/${finalAttrs.pname}-${finalAttrs.version}.7z";
    hash = "sha256-7OpnZJc9k5NiOPHAbtJGMQvsMg9j81DCvbfo0f7uJcw=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    installFonts
    p7zip
  ];

  meta = {
    description = "Japanese font based on Rounded M+ and Noto Sans Japanese";
    homepage = "http://jikasei.me/font/rounded-mgenplus";
    license = lib.licenses.ofl;
    maintainers = with lib.maintainers; [ mnacamura ];
    platforms = lib.platforms.all;
  };
})
