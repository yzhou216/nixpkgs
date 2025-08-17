{
  bzip2,
  cunit,
  fetchFromGitHub,
  groff,
  lib,
  man,
  meson,
  ncurses,
  ninja,
  nix-update-script,
  pkg-config,
  python3,
  stdenv,
  testers,
  xdg-utils,
  xz,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qman";
  version = "1.5.1";

  src = fetchFromGitHub {
    owner = "plp13";
    repo = "qman";
    tag = "v${finalAttrs.version}";
    hash = "sha256-z3ILbbwcCYZT8qabVaGnMCyZRag8djEI32i6G7cLL2A=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3.pkgs.cogapp
  ];

  buildInputs = [
    bzip2
    cunit
    ncurses
    xz
    zlib
  ];

  propagatedUserEnvPkgs = [
    groff
    man
    xdg-utils
  ];

  postPatch = ''
    patchShebangs src/qman_tests_list.sh

    substituteInPlace src/config_def.py \
      --replace-fail '/usr/bin/man' '${lib.getExe' man "man"}' \
      --replace-fail '/usr/bin/groff' '${lib.getExe' groff "groff"}' \
      --replace-fail '/usr/bin/whatis' '${lib.getExe' man "whatis"}' \
      --replace-fail '/usr/bin/apropos' '${lib.getExe' man "apropos"}' \
      --replace-fail '/usr/bin/xdg-open' '${lib.getExe' xdg-utils "xdg-open"}' \
      --replace-fail '/usr/bin/xdg-email' '${lib.getExe' xdg-utils "xdg-email"}'

    substituteInPlace {man/qman.1,doc/TROUBLESHOOTING.md} \
      --replace-fail '/usr/bin' '/run/current-system/sw/bin'
  '';

  mesonFlags = [ "-Dconfigdir=${placeholder "out"}/etc/xdg/qman" ];

  passthru = {
    updateScript = nix-update-script { };
    tests.version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "qman --version";
    };
  };

  meta = {
    description = "Modern man page viewer";
    homepage = "https://github.com/plp13/qman";
    license = lib.licenses.bsd2;
    mainProgram = "qman";
    maintainers = with lib.maintainers; [
      yiyu
      kpbaks
    ];
    platforms = lib.platforms.all;
  };
})
