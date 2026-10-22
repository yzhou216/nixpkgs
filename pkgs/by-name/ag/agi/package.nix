{
  lib,
  stdenvNoCC,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  installIcons,
  wrapGAppsHook3,
  gobject-introspection,
  gdk-pixbuf,
  jre,
  android-tools,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "agi";
  version = "3.3.1";

  src = fetchzip {
    url = "https://github.com/google/agi/releases/download/${finalAttrs.version}/agi-${finalAttrs.version}-linux.zip";
    hash = "sha256-Yawl6InBYSWNw3clHyGAeC2PVfXEzWmbd6vcYrqAPO0=";
  };

  nativeBuildInputs = [
    wrapGAppsHook3
    gdk-pixbuf
    gobject-introspection
    autoPatchelfHook
    copyDesktopItems
    installIcons
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ./{agi,gapis,gapir,gapit,device-info} $out/bin
    cp -r lib $out

    installIcon --name agi icon.png

    runHook postInstall
  '';

  dontWrapGApps = true;

  preFixup = ''
    wrapProgram $out/bin/agi \
      --add-flags "--vm ${jre}/bin/java" \
      --add-flags "--adb ${android-tools}/bin/adb" \
      --add-flags "--jar $out/lib/gapic.jar" \
      "''${gappsWrapperArgs[@]-}"
  '';

  desktopItems = lib.toList (makeDesktopItem {
    name = "agi";
    desktopName = "Android GPU Inspector";
    exec = "agi";
    icon = "agi";
    categories = [
      "Development"
      "Debugger"
      "Graphics"
      "3DGraphics"
    ];
  });

  meta = {
    description = "Android GPU Inspector";
    homepage = "https://gpuinspector.dev";
    changelog = "https://github.com/google/agi/releases/tag/v${finalAttrs.version}";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ kashw2 ];
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
  };
})
