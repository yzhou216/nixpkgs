{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  makeBinaryWrapper,
  wrapGAppsHook3,
  gobject-introspection,
  python3Packages,
  gtk3,
  ibus,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ibus-handwrite-chinese";
  version = "0.6.0";
  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "ai-space-lab";
    repo = "ibus-handwrite-chinese";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9OzaQkQ780iEF36fVI4lpL1M1HdB5qjlTKcvWtxDQjs=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    wrapGAppsHook3
    gobject-introspection
  ];

  buildInputs = [
    gtk3
    ibus
  ];

  pythonEnv = python3Packages.python.withPackages (ps: [
    ps.pygobject3
    ps.evdev
    ps.numpy
    ps.onnxruntime
  ]);

  patchPhase = ''
    runHook prePatch

    # Patch the model download path to a user-writable location.
    # Both files have plain quoted strings; os is already imported in
    # both.
    sed -i 's|"/usr/local/share/ibus-handwrite-chinese/models"|os.path.expanduser("~/.local/share/ibus-handwrite-chinese/models")|g' \
      src/handwrite_config.py \
      src/handwrite_model_download.py

    # Fix the XML component to point to the wrapped binary and store icon.
    # Use @out@ placeholder since $out is not yet expanded here.
    sed -i \
      -e 's|/usr/local/bin/ibus-engine-handwrite-chinese|@out@/bin/ibus-handwrite-chinese|g' \
      -e 's|/usr/local/share/ibus-handwrite-chinese/icons|@out@/share/ibus-handwrite-chinese/icons|g' \
      xml/handwrite-chinese.xml

    runHook postPatch
  '';

  installPhase = ''
    runHook preInstall

    # Substitute the actual store path into the XML
    sed -i "s|@out@|$out|g" xml/handwrite-chinese.xml

    # Engine script (0644, not executable) and Python modules together
    # in the share dir, mirroring the PKGBUILD's ENGINE_DIR. Running
    # the engine via `python3 <script>` puts this dir on sys.path[0],
    # so the engine's imports (handwrite_config, ...) resolve without
    # PYTHONPATH hacks.
    install -Dm644 src/ibus-engine-handwrite-chinese src/*.py \
      --target-directory="$out/share/ibus-handwrite-chinese"

    install -Dm755 tools/restore.sh tools/diagnose_trackpad.sh \
      --target-directory="$out/share/ibus-handwrite-chinese"

    install -Dm644 tools/99-trackpad-handwrite.rules \
      --target-directory="$out/lib/udev/rules.d"

    install -Dm644 icons/handwrite-chinese.svg \
      --target-directory="$out/share/ibus-handwrite-chinese/icons"

    install -Dm644 VERSION \
      --target-directory="$out/share/ibus-handwrite-chinese"

    install -Dm644 xml/handwrite-chinese.xml \
      --target-directory="$out/share/ibus/component"

    # Wrapper mirrors the `PKGBUILD`'s
    # `/usr/local/bin/ibus-engine-handwrite-chinese`: invoke the
    # engine script through the `pythonEnv` interpreter (which carries
    # pygobject3/evdev/numpy).  `wrapGAppsHook3` wraps `"$out/bin/*"`
    # at fixup time with `GI_TYPELIB_PATH` etc. collected from
    # `buildInputs`.
    makeWrapper "${finalAttrs.pythonEnv}/bin/python3" "$out/bin/ibus-handwrite-chinese" \
      --add-flags "$out/share/ibus-handwrite-chinese/ibus-engine-handwrite-chinese"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Chinese handwriting input engine for IBus with trackpad/touchpad support. Simplified & Traditional Chinese. Inspired by macOS Trackpad Handwriting";
    homepage = "https://github.com/ai-space-lab/ibus-handwrite-chinese";
    changelog = "https://github.com/ai-space-lab/ibus-handwrite-chinese/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ yiyu ];
    mainProgram = "ibus-handwrite-chinese";
    platforms = lib.platforms.all;
    isIbusEngine = true;
  };
})
