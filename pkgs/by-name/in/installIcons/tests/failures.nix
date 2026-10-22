{
  lib,
  runCommand,
  stdenvNoCC,
  testers,
  installIcons,
}:

let
  # Builds a package, named after the case, whose postInstall runs the given
  # commands, and expects the build to fail with the given message in its log.
  expectFailure =
    case:
    { message, postInstall }:
    {
      inherit message;
      failure = testers.testBuildFailure (
        stdenvNoCC.mkDerivation {
          name = "install-icons-test-failure-${case}";
          __structuredAttrs = true;
          dontUnpack = true;
          nativeBuildInputs = [ installIcons ];
          installPhase = ''
            runHook preInstall
            source ${./png.sh}
            writePngHeader square.png 48 48
            writePngHeader other.png 48 48
            writePngHeader wide.png 48 32
            writePngHeader unlisted.png 640 640
            writePngHeader odd.png 33 33
            writePngHeader large.png 1024 1024
            echo 'not a PNG file' > text.png
            echo 'not an SVG file' > text.svg
            echo '<svg xmlns="http://www.w3.org/2000/svg"/>' > icon.svg
            echo '<!DOCTYPE html><html><body><svg/></body></html>' > page.svg
            touch icon.xpm
            cp square.png .png
            cp square.png .hidden.png
            cp square.png icon.svg.png
            cp square.png png
            mkdir $out
            runHook postInstall
          '';
          inherit postInstall;
        }
      );
    };

  cases = lib.mapAttrs expectFailure {
    not-square = {
      message = "wide.png is 48x32, but icons must be square";
      postInstall = "installIcon wide.png";
    };
    unlisted-size = {
      message = "no 640x640/apps directory";
      postInstall = "installIcon unlisted.png";
    };
    unlisted-scaled-size = {
      message = "no 320x320@2/apps directory for unlisted.png; its sizes for apps at --scale 2 are 16 22";
      postInstall = "installIcon --scale 2 unlisted.png";
    };
    odd-size = {
      message = "no 33x33/apps directory for odd.png; its sizes";
      postInstall = "installIcon odd.png";
    };
    needs-scale = {
      message = "pass --scale 2 to install large.png into 512x512@2/apps";
      postInstall = "installIcon large.png";
    };
    not-multiple = {
      message = "48x48, which is not a multiple of --scale 5";
      postInstall = "installIcon --scale 5 square.png";
    };
    already-installed = {
      message = "48x48/apps/foo.png is already installed";
      postInstall = "installIcon --name foo square.png other.png";
    };
    dangling-symlink = {
      message = "48x48/apps/square.png is already installed";
      postInstall = ''
        mkdir -p $out/share/icons/hicolor/48x48/apps
        ln -s missing $out/share/icons/hicolor/48x48/apps/square.png
        installIcon square.png
      '';
    };
    not-png = {
      message = "text.png is not a PNG file";
      postInstall = "installIcon text.png";
    };
    not-svg = {
      message = "text.svg is not an SVG file";
      postInstall = "installIcon text.svg";
    };
    html-svg = {
      message = "page.svg is not an SVG file";
      postInstall = "installIcon page.svg";
    };
    no-default-name = {
      message = ".png has no valid icon name before its extension, only ''; pass --name";
      postInstall = "installIcon .png";
    };
    hidden-default-name = {
      message = ".hidden.png has no valid icon name before its extension, only '.hidden'";
      postInstall = "installIcon .hidden.png";
    };
    extension-default-name = {
      message = "icon.svg.png has no valid icon name before its extension, only 'icon.svg'";
      postInstall = "installIcon icon.svg.png";
    };
    no-extension = {
      message = "png is not a PNG or SVG file";
      postInstall = "installIcon png";
    };
    unsupported-format = {
      message = "icon.xpm is not a PNG or SVG file";
      postInstall = "installIcon icon.xpm";
    };
    missing-file = {
      message = "missing.png does not exist";
      postInstall = "installIcon missing.png";
    };
    no-files = {
      message = "expects at least one icon file";
      postInstall = "installIcon --name foo";
    };
    name-extension = {
      message = "--name expects an icon name without a directory or an extension, not 'foo.png'";
      postInstall = "installIcon --name foo.png square.png";
    };
    name-directory = {
      message = "--name expects an icon name without a directory or an extension, not 'apps/foo'";
      postInstall = "installIcon --name apps/foo square.png";
    };
    name-dot = {
      message = "--name expects an icon name without a directory or an extension, not '.foo'";
      postInstall = "installIcon --name .foo square.png";
    };
    empty-name = {
      message = "--name expects an icon name without a directory or an extension, not ''";
      postInstall = "installIcon --name '' square.png";
    };
    unknown-context = {
      message = "the hicolor theme has no chart context";
      postInstall = "installIcon --context chart square.png";
    };
    comma-context = {
      message = "the hicolor theme has no apps,48x48@2/apps context";
      postInstall = "installIcon --context apps,48x48@2/apps square.png";
    };
    svg-scale = {
      message = "--scale applies only to PNG icons";
      postInstall = "installIcon --scale 2 icon.svg";
    };
    bad-scale = {
      message = "--scale expects a positive integer";
      postInstall = "installIcon --scale 0 square.png";
    };
    overflowing-scale = {
      message = "--scale expects a positive integer, not '18446744073709551617'";
      postInstall = "installIcon --scale 18446744073709551617 square.png";
    };
    missing-argument = {
      message = "--name expects an argument";
      postInstall = "installIcon --name";
    };
    double-dash-argument = {
      message = "--name expects an argument";
      postInstall = "installIcon --name -- square.png";
    };
    unknown-option = {
      message = "unknown option --size";
      postInstall = "installIcon --size 48 square.png";
    };
  };
in
runCommand "install-icons-test-failures" { } ''
  ${lib.concatMapAttrsStringSep "\n" (name: case: ''
    if ! grep -qF -e ${lib.escapeShellArg case.message} ${case.failure}/testBuildFailure.log; then
      echo ${lib.escapeShellArg "${name}: expected the build log to contain: ${case.message}"}
      exit 1
    fi
  '') cases}
  touch $out
''
