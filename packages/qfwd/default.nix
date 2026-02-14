{ pkgs, ... }:

pkgs.writeShellScriptBin "qfwd" ''
  set -euo pipefail

  if [[ $# -lt 1 ]]; then
    echo "Usage: qfwd <box> [port...]" >&2
    echo "Forwards ports to <box>.eng.qumulo.com (default port: 8000)" >&2
    exit 1
  fi

  BOX=$1
  shift

  PORTS=("''${@:-8000}")

  ARGS=()
  for PORT in "''${PORTS[@]}"; do
    ARGS+=(-L "''${PORT}:127.0.0.1:''${PORT}")
  done

  exec ${pkgs.openssh}/bin/ssh "''${ARGS[@]}" -C -N -l philip "''${BOX}.eng.qumulo.com"
''
