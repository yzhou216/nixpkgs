{
  stdenvNoCC,
  installIcons,
}:

stdenvNoCC.mkDerivation {
  name = "install-icons-test-options";
  __structuredAttrs = true;
  dontUnpack = true;
  nativeBuildInputs = [ installIcons ];

  installPhase = ''
    runHook preInstall
    source ${./png.sh}
    writePngHeader -foo.png 22 22
    writePngHeader bar.png 32 32
    echo '<svg xmlns="http://www.w3.org/2000/svg"/>' > foo.svg
    mkdir $out
    runHook postInstall
  '';

  # Options also take the form --option=value, -- ends them, a context may span
  # several directories, and neither IFS nor a temporary name assignment
  # changes how icons are read or named
  postInstall = ''
    installIcon --context=mimetypes --name=application-x-foo foo.svg
    installIcon --context status -- -foo.png
    installIcon --context stock/chart foo.svg
    IFS=: name=baz installIcon bar.png

    icons=$out/share/icons/hicolor
    cmp foo.svg $icons/scalable/mimetypes/application-x-foo.svg
    cmp -- -foo.png $icons/22x22/status/-foo.png
    cmp foo.svg $icons/scalable/stock/chart/foo.svg
    cmp bar.png $icons/32x32/apps/bar.png
    [[ $(find $out -type f | wc -l) == 4 ]]
  '';
}
