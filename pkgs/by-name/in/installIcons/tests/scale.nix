{
  stdenvNoCC,
  installIcons,
}:

stdenvNoCC.mkDerivation {
  name = "install-icons-test-scale";
  __structuredAttrs = true;
  dontUnpack = true;
  nativeBuildInputs = [ installIcons ];

  installPhase = ''
    runHook preInstall
    source ${./png.sh}
    writePngHeader icon-1024.png 1024 1024
    writePngHeader icon-64.png 64 64
    mkdir $out
    runHook postInstall
  '';

  # With --scale 2, a PNG icon of N pixels goes into the directory for N/2 at @2
  postInstall = ''
    installIcon --scale 2 --name foo icon-1024.png icon-64.png

    icons=$out/share/icons/hicolor
    cmp icon-1024.png $icons/512x512@2/apps/foo.png
    cmp icon-64.png $icons/32x32@2/apps/foo.png
    [[ $(find $out -type f | wc -l) == 2 ]]
  '';
}
