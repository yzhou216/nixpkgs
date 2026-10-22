{
  stdenvNoCC,
  installIcons,
}:

stdenvNoCC.mkDerivation {
  name = "install-icons-test-sizes";
  __structuredAttrs = true;
  dontUnpack = true;
  nativeBuildInputs = [ installIcons ];

  installPhase = ''
    runHook preInstall
    source ${./png.sh}
    writePngHeader icon-16.png 16 16
    writePngHeader icon-32.PNG 32 32
    writePngHeader icon-256.png 256 256
    echo '<svg xmlns="http://www.w3.org/2000/svg"/>' > icon.svg
    mkdir $out
    runHook postInstall
  '';

  # One name for every size, with the extension in lower case
  postInstall = ''
    installIcon --name foo icon-*.png icon-32.PNG icon.svg

    icons=$out/share/icons/hicolor
    cmp icon-16.png $icons/16x16/apps/foo.png
    cmp icon-32.PNG $icons/32x32/apps/foo.png
    cmp icon-256.png $icons/256x256/apps/foo.png
    cmp icon.svg $icons/scalable/apps/foo.svg
    [[ $(find $out -type f | wc -l) == 4 ]]
  '';
}
