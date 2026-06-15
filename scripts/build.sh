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
APP_NAME="Snake Game"
AUTHOR="waskevin"
VERSION="1.0.001"
LOW_VERSION="TOS7.0"
LISTEN_PORT="18601"
SERVICE_ID="${APP_ID}-service"
SERVICE_USER="${APP_ID}"
SERVICE_PACKAGE="${APP_ID}-service"
DATA_PACKAGE="${APP_ID}-app"
CATEGORY="Utilities"
URL_PATH="http://\${ip}:${LISTEN_PORT}"
APP_TYPE="deb"
ICON_FILE="${APP_ID}.svg"
DESCRIPTION="A browser-open Snake game for TOS 7."
RELEASE_NOTE="Initial release with keyboard and touch controls, score tracking, and best-score memory."
IMPORTANT="If the page is unavailable, verify the service and network access to port ${LISTEN_PORT}."

LINUX_STAGE_ROOT="$(mktemp -d "/tmp/${APP_ID}-${TARGET}-XXXXXX")"
trap 'rm -rf "${LINUX_STAGE_ROOT}"' EXIT

BUILD_DIR="${LINUX_STAGE_ROOT}/build"
DIST_DIR="${LINUX_STAGE_ROOT}/dist"
DATA_ROOT="${BUILD_DIR}/data-root"
SERVICE_ROOT="${BUILD_DIR}/service-root"
WEBUI_STAGE="${BUILD_DIR}/webui"
HOST_DIST_DIR="${ROOT_DIR}/dist/${TARGET}"

write_lang_section() {
  local lang="$1"
  cat >> "${DATA_ROOT}/usr/local/${APP_ID}/${APP_ID}.lang" <<EOF_LANG
[${lang}]
name = "${APP_NAME}"
auth = "${AUTHOR}"
version = "${VERSION}"
descript = "${DESCRIPTION}"
release_note = "${RELEASE_NOTE}"
important = "${IMPORTANT}"

EOF_LANG
}

rm -rf "${HOST_DIST_DIR}"
mkdir -p \
  "${DATA_ROOT}/DEBIAN" \
  "${DATA_ROOT}/usr/local/${APP_ID}/images/icons" \
  "${DATA_ROOT}/usr/local/${APP_ID}/nginx" \
  "${SERVICE_ROOT}/DEBIAN" \
  "${SERVICE_ROOT}/usr/local/${APP_ID}/bin" \
  "${SERVICE_ROOT}/usr/local/${APP_ID}/web" \
  "${SERVICE_ROOT}/usr/local/${APP_ID}/init.d" \
  "${SERVICE_ROOT}/etc/systemd/system" \
  "${WEBUI_STAGE}" \
  "${DIST_DIR}" \
  "${HOST_DIST_DIR}"

cat > "${DATA_ROOT}/DEBIAN/control" <<EOF_CONTROL
Package: ${DATA_PACKAGE}
Version: ${VERSION}
Section: games
Priority: optional
Architecture: all
Depends: ${SERVICE_PACKAGE} (= ${VERSION})
Maintainer: ${AUTHOR}
Description: TOS metadata package for ${APP_NAME}
EOF_CONTROL

cat > "${SERVICE_ROOT}/DEBIAN/control" <<EOF_CONTROL
Package: ${SERVICE_PACKAGE}
Version: ${VERSION}
Section: games
Priority: optional
Architecture: ${DEB_ARCH}
Depends: python3
Maintainer: ${AUTHOR}
Description: Runnable service package for ${APP_NAME}
EOF_CONTROL

cat > "${DATA_ROOT}/usr/local/${APP_ID}/config.ini" <<EOF_CONFIG
{
  "id": "${APP_ID}",
  "icon": "/images/icons/${ICON_FILE}",
  "publisher": "${AUTHOR}",
  "path": "${URL_PATH}",
  "exec": true,
  "open_path": true,
  "resize": true,
  "maxmin": true,
  "width": 0,
  "height": 0,
  "help": "https://github.com/waskevin/snake-game",
  "version": "${VERSION}",
  "recommend": false,
  "beta": false,
  "low_version": "${LOW_VERSION}",
  "category": ["${CATEGORY}"],
  "depend": [],
  "relation": [],
  "platform": "${PLATFORM}",
  "official": "https://github.com/waskevin/snake-game",
  "application_type": "${APP_TYPE}",
  "system_id": "${SERVICE_ID}",
  "package": "${DATA_PACKAGE}",
  "user": "${SERVICE_USER}",
  "all_user_display": true
}
EOF_CONFIG

: > "${DATA_ROOT}/usr/local/${APP_ID}/${APP_ID}.lang"
for lang in de-de en-us es-es fr-fr hu-hu it-it ja-jp ko-kr pl-pl pt-pt ru-ru tr-tr zh-cn zh-hk; do
  write_lang_section "${lang}"
done

cat > "${DATA_ROOT}/usr/local/${APP_ID}/nginx/${APP_ID}.conf" <<EOF_NGINX
location /${APP_ID}/ {
    proxy_pass http://127.0.0.1:${LISTEN_PORT}/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
}
EOF_NGINX

cat > "${SERVICE_ROOT}/usr/local/${APP_ID}/init.d/${SERVICE_ID}.service" <<EOF_SERVICE
[Unit]
Description=${APP_NAME}
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=/usr/local/${APP_ID}
ExecStart=/usr/bin/python3 /usr/local/${APP_ID}/bin/server.py --port ${LISTEN_PORT} --host 0.0.0.0 --web-root /usr/local/${APP_ID}/web

[Install]
WantedBy=multi-user.target
EOF_SERVICE

cp "${ROOT_DIR}/assets/${ICON_FILE}" "${DATA_ROOT}/usr/local/${APP_ID}/images/icons/${ICON_FILE}"
cp "${ROOT_DIR}/app/index.html" "${WEBUI_STAGE}/index.html"
cp "${ROOT_DIR}/app/snake.css" "${WEBUI_STAGE}/snake.css"
cp "${ROOT_DIR}/app/snake.js" "${WEBUI_STAGE}/snake.js"
tar --format=gnu -cjf "${SERVICE_ROOT}/usr/local/${APP_ID}/webui.bz2" -C "${WEBUI_STAGE}" .

cp "${ROOT_DIR}/app/server.py" "${SERVICE_ROOT}/usr/local/${APP_ID}/bin/server.py"
cp "${ROOT_DIR}/app/index.html" "${SERVICE_ROOT}/usr/local/${APP_ID}/web/index.html"
cp "${ROOT_DIR}/app/snake.css" "${SERVICE_ROOT}/usr/local/${APP_ID}/web/snake.css"
cp "${ROOT_DIR}/app/snake.js" "${SERVICE_ROOT}/usr/local/${APP_ID}/web/snake.js"
cp "${SERVICE_ROOT}/usr/local/${APP_ID}/init.d/${SERVICE_ID}.service" "${SERVICE_ROOT}/etc/systemd/system/${SERVICE_ID}.service"

cat > "${SERVICE_ROOT}/DEBIAN/preinst" <<EOF_PREINST
#!/bin/sh
set -e
if ! id -u ${SERVICE_USER} >/dev/null 2>&1; then
  useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin ${SERVICE_USER} >/dev/null 2>&1 || true
fi
exit 0
EOF_PREINST

cat > "${SERVICE_ROOT}/DEBIAN/postinst" <<EOF_POSTINST
#!/bin/sh
set -e
chown -R ${SERVICE_USER}:${SERVICE_USER} /usr/local/${APP_ID}/web /usr/local/${APP_ID}/bin || true
systemctl daemon-reload || true
systemctl enable ${SERVICE_ID}.service || true
systemctl restart ${SERVICE_ID}.service || systemctl start ${SERVICE_ID}.service || true
exit 0
EOF_POSTINST

cat > "${SERVICE_ROOT}/DEBIAN/prerm" <<EOF_PRERM
#!/bin/sh
set -e
systemctl stop ${SERVICE_ID}.service || true
systemctl disable ${SERVICE_ID}.service || true
exit 0
EOF_PRERM

cat > "${SERVICE_ROOT}/DEBIAN/postrm" <<EOF_POSTRM
#!/bin/sh
set -e
systemctl daemon-reload || true
exit 0
EOF_POSTRM

chmod 0755 \
  "${SERVICE_ROOT}/DEBIAN/preinst" \
  "${SERVICE_ROOT}/DEBIAN/postinst" \
  "${SERVICE_ROOT}/DEBIAN/prerm" \
  "${SERVICE_ROOT}/DEBIAN/postrm"

find "${DATA_ROOT}" -type d -exec chmod 0755 {} +
find "${SERVICE_ROOT}" -type d -exec chmod 0755 {} +
find "${DATA_ROOT}/usr/local/${APP_ID}" -type f -exec chmod 0644 {} +
find "${SERVICE_ROOT}/usr/local/${APP_ID}" -type f -exec chmod 0644 {} +
chmod 0644 "${SERVICE_ROOT}/etc/systemd/system/${SERVICE_ID}.service"
chmod 0755 "${DATA_ROOT}/DEBIAN" "${SERVICE_ROOT}/DEBIAN"
chmod 0644 "${DATA_ROOT}/DEBIAN/control" "${SERVICE_ROOT}/DEBIAN/control"

DATA_DEB="${DIST_DIR}/${DATA_PACKAGE}_${VERSION}_all.deb"
SERVICE_DEB="${DIST_DIR}/${SERVICE_PACKAGE}_${VERSION}_${DEB_ARCH}.deb"
FINAL_TAR="${DIST_DIR}/${APP_ID}_${PLATFORM}.tar.gz"
SHA256_FILE="${DIST_DIR}/${APP_ID}_${PLATFORM}.tar.gz.sha256"

dpkg-deb --build "${DATA_ROOT}" "${DATA_DEB}"
dpkg-deb --build "${SERVICE_ROOT}" "${SERVICE_DEB}"

TMP_TAR_DIR="${BUILD_DIR}/tar"
mkdir -p "${TMP_TAR_DIR}"
cp "${DATA_DEB}" "${TMP_TAR_DIR}/${APP_ID}.deb"
cp "${SERVICE_DEB}" "${TMP_TAR_DIR}/${SERVICE_PACKAGE}.deb"

tar --format=gnu -czf "${FINAL_TAR}" -C "${TMP_TAR_DIR}" "${APP_ID}.deb" "${SERVICE_PACKAGE}.deb"
(
  cd "${DIST_DIR}"
  sha256sum "$(basename "${FINAL_TAR}")" > "$(basename "${SHA256_FILE}")"
)

cp "${DATA_DEB}" "${HOST_DIST_DIR}/"
cp "${SERVICE_DEB}" "${HOST_DIST_DIR}/"
cp "${FINAL_TAR}" "${HOST_DIST_DIR}/"
cp "${SHA256_FILE}" "${HOST_DIST_DIR}/"

echo "Built artifacts:"
echo "  ${HOST_DIST_DIR}/$(basename "${DATA_DEB}")"
echo "  ${HOST_DIST_DIR}/$(basename "${SERVICE_DEB}")"
echo "  ${HOST_DIST_DIR}/$(basename "${FINAL_TAR}")"
echo "  ${HOST_DIST_DIR}/$(basename "${SHA256_FILE}")"
