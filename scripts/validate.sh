#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGET="${1:-amd64}"

case "${TARGET}" in
  amd64)
    DEB_ARCH="amd64"
    PLATFORM="x86_64"
    ;;
  arm64)
    DEB_ARCH="arm64"
    PLATFORM="aarch64"
    ;;
  *)
    echo "Unsupported target: ${TARGET}. Use amd64 or arm64." >&2
    exit 1
    ;;
esac

APP_ID="snake-game"
VERSION="1.0.0"
DIST_DIR="${ROOT_DIR}/dist/${TARGET}"
DATA_DEB="${DIST_DIR}/${APP_ID}-app_${VERSION}_all.deb"
SERVICE_DEB="${DIST_DIR}/${APP_ID}-service_${VERSION}_${DEB_ARCH}.deb"
FINAL_TAR="${DIST_DIR}/${APP_ID}_${PLATFORM}.tar.gz"
SHA256_FILE="${DIST_DIR}/${APP_ID}_${PLATFORM}.tar.gz.sha256"

require_file() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    echo "Missing file: ${file}" >&2
    exit 1
  fi
}

require_contains() {
  local file="$1"
  local pattern="$2"
  if ! grep -qE "${pattern}" "${file}"; then
    echo "Expected pattern not found in ${file}: ${pattern}" >&2
    exit 1
  fi
}

require_file "${DATA_DEB}"
require_file "${SERVICE_DEB}"
require_file "${FINAL_TAR}"
require_file "${SHA256_FILE}"

INSPECT_DIR="$(mktemp -d "/tmp/${APP_ID}-validate-${TARGET}-XXXXXX")"
trap 'rm -rf "${INSPECT_DIR}"' EXIT

tar -tzf "${FINAL_TAR}" | sort > "${INSPECT_DIR}/tar-list.txt"
require_contains "${INSPECT_DIR}/tar-list.txt" '^snake-game\.deb$'
require_contains "${INSPECT_DIR}/tar-list.txt" '^snake-game-service\.deb$'

(
  cd "${DIST_DIR}"
  sha256sum -c "$(basename "${SHA256_FILE}")" >/dev/null
)

dpkg-deb -x "${DATA_DEB}" "${INSPECT_DIR}/data"
dpkg-deb -x "${SERVICE_DEB}" "${INSPECT_DIR}/service"
dpkg-deb -f "${DATA_DEB}" > "${INSPECT_DIR}/data-control.txt"
dpkg-deb -f "${SERVICE_DEB}" > "${INSPECT_DIR}/service-control.txt"

APP_DIR="${INSPECT_DIR}/data/usr/local/${APP_ID}"
SERVICE_DIR="${INSPECT_DIR}/service/usr/local/${APP_ID}"

require_file "${APP_DIR}/config.ini"
require_file "${APP_DIR}/${APP_ID}.lang"
require_file "${APP_DIR}/images/icons/${APP_ID}.svg"
require_file "${APP_DIR}/nginx/${APP_ID}.conf"
require_file "${SERVICE_DIR}/bin/server.py"
require_file "${SERVICE_DIR}/web/index.html"
require_file "${SERVICE_DIR}/web/snake.css"
require_file "${SERVICE_DIR}/web/snake.js"
require_file "${SERVICE_DIR}/webui.bz2"
require_file "${SERVICE_DIR}/init.d/${APP_ID}-service.service"
require_file "${INSPECT_DIR}/service/etc/systemd/system/${APP_ID}-service.service"

if [[ -e "${APP_DIR}/webui.bz2" || -d "${APP_DIR}/init.d" || -d "${APP_DIR}/bin" ]]; then
  echo "Data package must contain metadata only, not runnable or binary assets." >&2
  exit 1
fi

python3 -m json.tool "${APP_DIR}/config.ini" >/dev/null
python3 - <<PY
import json
from pathlib import Path

cfg = json.loads(Path("${APP_DIR}/config.ini").read_text())
expected = {
    "id": "snake-game",
    "icon": "/images/icons/snake-game.svg",
    "publisher": "waskevin",
    "path": "http://\${ip}:18601",
    "exec": True,
    "open_path": True,
    "resize": True,
    "maxmin": True,
    "width": 0,
    "height": 0,
    "version": "1.0.0",
    "low_version": "TOS7.0",
    "category": ["Utilities"],
    "depend": [],
    "relation": [],
    "platform": "${PLATFORM}",
    "application_type": "deb",
    "system_id": "snake-game-service",
    "package": "snake-game-app",
    "user": "snake-game",
    "all_user_display": True,
}
for key, value in expected.items():
    if cfg.get(key) != value:
        raise SystemExit(f"Unexpected config value for {key}: {cfg.get(key)!r}")
PY

require_contains "${APP_DIR}/nginx/${APP_ID}.conf" 'proxy_pass http://127\.0\.0\.1:18601/;'
require_contains "${SERVICE_DIR}/init.d/${APP_ID}-service.service" '^User=snake-game$'
require_contains "${SERVICE_DIR}/init.d/${APP_ID}-service.service" '^ExecStart=/usr/bin/python3 /usr/local/snake-game/bin/server.py'

LANG_COUNT="$(grep -c '^\[' "${APP_DIR}/${APP_ID}.lang")"
if [[ "${LANG_COUNT}" != "14" ]]; then
  echo "Expected 14 language sections, found ${LANG_COUNT}" >&2
  exit 1
fi

if grep -q '^Restart=' "${SERVICE_DIR}/init.d/${APP_ID}-service.service" "${INSPECT_DIR}/service/etc/systemd/system/${APP_ID}-service.service"; then
  echo "Restart must not be configured in systemd service files." >&2
  exit 1
fi

require_contains "${INSPECT_DIR}/data-control.txt" '^Package: snake-game-app$'
require_contains "${INSPECT_DIR}/data-control.txt" '^Architecture: all$'
require_contains "${INSPECT_DIR}/data-control.txt" '^Depends: snake-game-service \(= 1\.0\.0\)$'
require_contains "${INSPECT_DIR}/service-control.txt" '^Package: snake-game-service$'
require_contains "${INSPECT_DIR}/service-control.txt" '^Architecture: '"${DEB_ARCH}"'$'

echo "Validation passed for ${TARGET}."
