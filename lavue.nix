{ lib
, fetchFromGitHub
, python3Packages
, wrapGAppsHook3
, qt5
}:

python3Packages.buildPythonApplication rec {
  pname = "lavue";
  version = "2.89.3";

  src = fetchFromGitHub {
    owner = "lavue-org";
    repo = "lavue";
    rev = "v${version}";
    hash = "sha256-HZaRxYGxCunB650N216JI90+6GPUdLuj8JaVMN8YJNw=";
  };

  propagatedBuildInputs = with python3Packages; [
    pyqt5
    pillow
    fabio
    requests
    pyqtgraph
    numpy
    pyzmq
    scipy
    h5py
  ];

  nativeBuildInputs = [
    wrapGAppsHook3
    qt5.wrapQtAppsHook
  ];

  meta = with lib; {
    description = "Lightweight Live Viewer";
    homepage = "https://github.com/lavue-org/lavue";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ pmiddend ];
    mainProgram = "lavue";
  };
}

