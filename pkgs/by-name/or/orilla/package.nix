{
  lib,
  rustPlatform,
  fetchFromSourcehut,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "orilla";
  version = "0.1.0";
  __structuredAttrs = true;

  src = fetchFromSourcehut {
    owner = "~hokiegeek";
    repo = "orilla";
    tag = "orilla-core-v${finalAttrs.version}";
    hash = "sha256-akoEJnl+yzygHgIt687Y6osGzTwtxLWmy4/OgCB3O1g=";
  };

  cargoHash = "sha256-fTKgRSDtV+5Dn4QAfBYsUbdaNj5GsVAwnYVwpw7VJms=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Window manager for the river Wayland compositor";
    homepage = "https://git.sr.ht/~hokiegeek/orilla";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ yiyu ];
  };
})
