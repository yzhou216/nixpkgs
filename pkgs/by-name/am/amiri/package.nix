{
  lib,
  stdenvNoCC,
  fetchzip,
  installFonts,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "amiri";
  version = "1.003";

  src = fetchzip {
    url = "https://github.com/aliftype/amiri/releases/download/${finalAttrs.version}/Amiri-${finalAttrs.version}.zip";
    hash = "sha256-BsYPMBlRdzlkvyleZIxGDuGjmqhDlEJ4udj8zoKUSzA=";
  };

  nativeBuildInputs = [ installFonts ];

  installPhase = ''
    runHook preInstall

    install -Dm644 {*.html,*.txt,*.md} \
      --target-directory=$out/share/doc/${finalAttrs.pname}-${finalAttrs.version}

    runHook postInstall
  '';

  meta = {
    description = "Classical Arabic typeface in Naskh style";
    longDescription = ''
      Amiri (أميري) is a classical Arabic typeface in Naskh style for
      typesetting books and other running text.

      Amiri is a revival of the beautiful typeface pioneered in early
      20th century by Bulaq Press in Cairo, also known as Amiria
      Press, after which the font is named.

      The uniqueness of this typeface comes from its superb balance
      between the beauty of Naskh calligraphy on one hand, the
      constraints and requirements of elegant typography on the other.
      Also, it is one of the few metal typefaces that were used in
      typesetting the Quran, making it a good source for a digital
      typeface to be used in typesetting Quranic verses.

      Amiri project aims at the revival of the aesthetics and
      traditions of Arabic typesetting, and adapting it to the era of
      digital typesetting, in a publicly available form.
    '';
    homepage = "https://www.amirifont.org";
    license = lib.licenses.ofl;
    maintainers = [ lib.maintainers.vbgl ];
    platforms = lib.platforms.all;
  };
})
