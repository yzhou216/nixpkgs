{
  fetchFromGitHub,
  jdk_headless,
  jre,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "osp";
  version = "6.3.3";

  src = fetchFromGitHub {
    owner = "OpenSourcePhysics";
    repo = "osp";
    tag = "version_${finalAttrs.version}";
    hash = "sha256-ukJ/jzNK1zO19PzyDdWHfoZU9montlwfKMt7sk/x6tU=";
  };

  strictDeps = true;

  nativeBuildInputs = [ jdk_headless ];

  buildPhase = ''
    runHook preBuild

    javac \
      -source 1.8 -target 1.8 \
      -d build/classes \
      $(find src -type f -name "*.java")

    jar cfe dist/jars/osp.jar org.opensourcephysics.tools.Launcher \
      -C build/classes .

    jar uf dist/jars/osp.jar -C src org/opensourcephysics/resources

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 dist/jars/*.jar \
      --target-directory="$out"/share/java/osp

    runHook postInstall
  '';

  meta = {
    description = "Open Source Physics Core Library";
    homepage = "https://github.com/OpenSourcePhysics/osp";
    inherit (jre.meta) platforms;
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ yiyu ];
  };
})
