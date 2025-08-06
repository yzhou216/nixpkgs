{
  lib,
  buildPythonPackage,
  fetchPypi,
  poetry-core,
  xdg,
}:

buildPythonPackage rec {
  pname = "uniproxy";
  version = "1.5.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-l71vYlUCXsncXiEQ/Y1egdddhQ0b500DoLtTSqw5QVk=";
  };

  build-system = [ poetry-core ];

  dependencies = [ xdg ];

  pythonImportsCheck = [ "uniproxy" ];

  meta = {
    description = "Set system-wide proxy and bypass domains for proxy";
    homepage = "https://pypi.org/project/Uniproxy/";
    license = with lib.licenses; [
      lgpl2Only
      lgpl21Only
    ];
    maintainers = with lib.maintainers; [ yiyu ];
    mainProgram = "uniproxy";
  };
}
