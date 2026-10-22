{
  stdenvNoCC,
  installIcons,
}:

stdenvNoCC.mkDerivation {
  name = "install-icons-test-outputs";
  __structuredAttrs = true;
  outputs = [
    "out"
    "bin"
  ];
  dontUnpack = true;
  nativeBuildInputs = [ installIcons ];

  installPhase = ''
    runHook preInstall
    echo '<svg xmlns="http://www.w3.org/2000/svg"/>' > foo.svg
    mkdir $out $bin
    runHook postInstall
  '';

  # Icons go into outputBin
  postInstall = ''
    installIcon foo.svg

    cmp foo.svg $bin/share/icons/hicolor/scalable/apps/foo.svg
    [[ ! -e $out/share ]]
  '';
}
