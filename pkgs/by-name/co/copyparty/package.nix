{
  lib,
  python3,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "copyparty";
  version = "1.18.9";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "9001";
    repo = "copyparty";
    tag = "v${version}";
    hash = "sha256-3ziocVJcVQ0cBia8Sp91uMkcVdh6l4rm/huhvAKfXzA=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    jinja2
    fusepy
  ];

  optional-dependencies = with python3.pkgs; {
    audiotags = [ mutagen ];
    ftpd = [ pyftpdlib ];
    ftps = [
      pyftpdlib
      pyopenssl
    ];
    pwhash = [ argon2-cffi ];
    tftpd = [ partftpy ];
    thumbnails = [ pillow ];
    thumbnails2 = [ pyvips ];
    zeromq = [ pyzmq ];
  };

  pythonImportsCheck = [ "copyparty" ];

  postInstall = ''
    rm -rf $out/bin/*.py
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Portable file server with accelerated resumable uploads";
    longDescription = ''
      Turn almost any device into a file server with resumable
      uploads/downloads using any web browser. dedup, WebDAV, FTP,
      TFTP, zeroconf, media indexer, thumbnails++ all in one file, no
      deps.
    '';
    homepage = "https://github.com/9001/copyparty";
    changelog = "https://github.com/9001/copyparty/releases/tag/${src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ yiyu ];
    mainProgram = "copyparty";
  };
}
