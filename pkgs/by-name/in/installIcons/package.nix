{
  lib,
  callPackage,
  hicolor-icon-theme,
  makeSetupHook,
}:

# See the header comment in ./install-icons.sh for example usage.
makeSetupHook {
  name = "install-icons-hook";
  substitutions = {
    # Directories that the hook may install icons into
    indexTheme = "${hicolor-icon-theme}/share/icons/hicolor/index.theme";
  };
  passthru.tests = lib.packagesFromDirectoryRecursive {
    inherit callPackage;
    directory = ./tests;
  };
  meta = {
    description = "Setup hook that installs icons into the hicolor theme directory that matches their size";
    maintainers = with lib.maintainers; [ yiyu ];
    license = lib.licenses.mit;
  };
} ./install-icons.sh
