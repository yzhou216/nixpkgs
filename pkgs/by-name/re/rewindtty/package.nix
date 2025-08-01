{
  lib,
  stdenv,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rewindtty";
  version = "0.0.6-dev";

  src = fetchFromGitHub {
    owner = "debba";
    repo = "rewindtty";
    rev = finalAttrs.version;
    hash = "sha256-BaZIGOw7uNxTFdr7fG07+rNGly305mwJ05POp32fTLs=";
    fetchSubmodules = true;
  };

  installPhase = ''
    runHook preInstall

    install -Dm755 build/rewindtty $out/bin/${finalAttrs.meta.mainProgram}

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Terminal session recorder and replayer";
    longDescription = ''
      A terminal session recorder and replayer written in C that
      allows you to capture and replay terminal sessions with precise
      timing.
    '';
    homepage = "https://github.com/debba/rewindtty";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ yiyu ];
    mainProgram = "rewindtty";
    platforms = lib.platforms.all;
  };
})
