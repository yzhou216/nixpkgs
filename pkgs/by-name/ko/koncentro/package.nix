{
  lib,
  python3,
  fetchFromGitHub,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "koncentro";
  version = "1.0.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "kun-codes";
    repo = "Koncentro";
    rev = "v${version}";
    hash = "sha256-j0HOAdKDSW2PQ8yQy3dzTX3fNaCDRQM3MMhJ+ZfDNok=";
  };

  build-system = with python3.pkgs; [ poetry-core ];

  dependencies = with python3.pkgs; [
    alembic
    certifi
    loguru
    psutil
    pyside6
    pyside6-fluent-widgets
    semver
    sqlalchemy
    uniproxy
    validators
  ];

  pythonImportsCheck = [ "koncentro" ];

  postPatch = ''
    mv src koncentro
  '';

  meta = {
    description = "Powerful productivity app";
    longDescription = ''
      A powerful productivity app combining Pomodoro technique, task
      management, and website blocking.
    '';
    homepage = "https://github.com/kun-codes/Koncentro";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ yiyu ];
    mainProgram = "koncentro";
  };
}
