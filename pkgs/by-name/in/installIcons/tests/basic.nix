{
  stdenvNoCC,
  installIcons,
}:

stdenvNoCC.mkDerivation {
  name = "install-icons-test-basic";
  dontUnpack = true;
  nativeBuildInputs = [ installIcons ];

  installPhase = ''
    runHook preInstall
    source ${./png.sh}
    writePngHeader foo.png 48 48
    echo '<svg xmlns="http://www.w3.org/2000/svg"/>' > bar.svg
    mkdir $out
    runHook postInstall
  '';

  # Each icon is named after its file, and goes into the directory for its size
  postInstall = ''
    installIcon foo.png bar.svg

    icons=$out/share/icons/hicolor
    cmp foo.png $icons/48x48/apps/foo.png
    cmp bar.svg $icons/scalable/apps/bar.svg
    [[ $(stat -c %a $icons/48x48/apps/foo.png) == 644 ]]
    [[ $(find $out -type f | wc -l) == 2 ]]
  '';
}
