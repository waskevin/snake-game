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
APP_NAME_ZH="贪吃蛇"
APP_NAME_EN="Snake Game"
AUTHOR="Codex"
VERSION="1.0.0"
LOW_VERSION="7.0"
LISTEN_PORT="18601"
SERVICE_ID="${APP_ID}-service"
SERVICE_USER="${APP_ID}"
SERVICE_PACKAGE="${APP_ID}-service"
DATA_PACKAGE="${APP_ID}-app"
CATEGORY="Utilities"
URL_PATH="/${APP_ID}/"
APP_TYPE="deb"
ICON_FILE="${APP_ID}.svg"

DESCRIPTION_ZH="一个在浏览器新标签页打开的贪吃蛇小游戏。"
DESCRIPTION_EN="A Snake game that opens in a browser tab through the TOS app center."
RELEASE_NOTE_ZH="首个版本，包含键盘和触屏控制、积分统计与最高分记录。"
RELEASE_NOTE_EN="Initial release with keyboard and touch controls, score tracking, and best-score memory."
IMPORTANT_ZH="如页面无法访问，请确认 nginx 路由与 systemd 服务状态正常。"
IMPORTANT_EN="If the page is unavailable, verify the nginx route and the systemd service status."

LINUX_STAGE_ROOT="$(mktemp -d "/tmp/${APP_ID}-${TARGET}-XXXXXX")"
trap 'rm -rf "${LINUX_STAGE_ROOT}"' EXIT

BUILD_DIR="${LINUX_STAGE_ROOT}/build"
DIST_DIR="${LINUX_STAGE_ROOT}/dist"
DATA_ROOT="${BUILD_DIR}/data-root"
SERVICE_ROOT="${BUILD_DIR}/service-root"
WEBUI_STAGE="${BUILD_DIR}/webui"
HOST_DIST_DIR="${ROOT_DIR}/dist/${TARGET}"

normalize_line_endings() {
  while IFS= read -r -d '' file; do
    perl -0pi -e 's/\r\n/\n/g' "$file"
  done < <(find "${ROOT_DIR}" -type f \( \
    -name '*.sh' -o \
    -name '*.py' -o \
    -name '*.ini' -o \
    -name '*.lang' -o \
    -name '*.service' -o \
    -name '*.conf' -o \
    -name '*.html' -o \
    -name '*.css' -o \
    -name '*.js' \
  \) -print0)
}

write_lang_section() {
  local lang="$1"
  local name="$2"
  local descript="$3"
  local release_note="$4"
  local important="$5"
  cat >> "${DATA_ROOT}/usr/local/${APP_ID}/${APP_ID}.lang" <<EOF
[${lang}]
name = "${name}"
auth = "${AUTHOR}"
version = "${VERSION}"
descript = "${descript}"
release_note = "${release_note}"
important = "${important}"

EOF
}

normalize_line_endings

rm -rf "${HOST_DIST_DIR}"
mkdir -p \
  "${DATA_ROOT}/DEBIAN" \
  "${DATA_ROOT}/usr/local/${APP_ID}/images/icons" \
  "${DATA_ROOT}/usr/local/${APP_ID}/nginx" \
  "${DATA_ROOT}/usr/local/${APP_ID}/init.d" \
  "${SERVICE_ROOT}/DEBIAN" \
  "${SERVICE_ROOT}/usr/local/${APP_ID}/bin" \
  "${SERVICE_ROOT}/usr/local/${APP_ID}/web" \
  "${SERVICE_ROOT}/etc/systemd/system" \
  "${WEBUI_STAGE}" \
  "${DIST_DIR}" \
  "${HOST_DIST_DIR}"

cat > "${DATA_ROOT}/DEBIAN/control" <<EOF
Package: ${DATA_PACKAGE}
Version: ${VERSION}
Section: games
Priority: optional
Architecture: ${DEB_ARCH}
Depends: ${SERVICE_PACKAGE} (= ${VERSION})
Maintainer: ${AUTHOR}
Description: TOS metadata package for ${APP_NAME_EN}
EOF

cat > "${SERVICE_ROOT}/DEBIAN/control" <<EOF
Package: ${SERVICE_PACKAGE}
Version: ${VERSION}
Section: games
Priority: optional
Architecture: ${DEB_ARCH}
Depends: python3
Maintainer: ${AUTHOR}
Description: Runnable service package for ${APP_NAME_EN}
EOF

cat > "${DATA_ROOT}/usr/local/${APP_ID}/config.ini" <<EOF
{
  "id": "${APP_ID}",
  "icon": "/images/icons/${ICON_FILE}",
  "exec": true,
  "version": "${VERSION}",
  "category": ["${CATEGORY}"],
  "platform": "${PLATFORM}",
  "system_id": "${SERVICE_ID}",
  "package": "${DATA_PACKAGE}",
  "application_type": "${APP_TYPE}",
  "path": "${URL_PATH}",
  "open_path": true,
  "low_version": "${LOW_VERSION}",
  "recommend": false,
  "beta": false,
  "official": "https://github.com/jwlv-1314/test2026"
}
EOF

: > "${DATA_ROOT}/usr/local/${APP_ID}/${APP_ID}.lang"
write_lang_section "de-de" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "en-us" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "es-es" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "fr-fr" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "hu-hu" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "it-it" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "ja-jp" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "ko-kr" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "pl-pl" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "pt-pt" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "ru-ru" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "tr-tr" "${APP_NAME_EN}" "${DESCRIPTION_EN}" "${RELEASE_NOTE_EN}" "${IMPORTANT_EN}"
write_lang_section "zh-cn" "${APP_NAME_ZH}" "${DESCRIPTION_ZH}" "${RELEASE_NOTE_ZH}" "${IMPORTANT_ZH}"
write_lang_section "zh-hk" "${APP_NAME_ZH}" "${DESCRIPTION_ZH}" "${RELEASE_NOTE_ZH}" "${IMPORTANT_ZH}"

cat > "${DATA_ROOT}/usr/local/${APP_ID}/nginx/${APP_ID}.conf" <<EOF
location ${URL_PATH} {
    proxy_pass http://127.0.0.1:${LISTEN_PORT}/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
}
EOF

cat > "${DATA_ROOT}/usr/local/${APP_ID}/init.d/${SERVICE_ID}.service" <<EOF
[Unit]
Description=${APP_NAME_EN}
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=/usr/local/${APP_ID}
ExecStart=/usr/bin/python3 /usr/local/${APP_ID}/bin/server.py --port ${LISTEN_PORT} --host 0.0.0.0 --web-root /usr/local/${APP_ID}/web

[Install]
WantedBy=multi-user.target
EOF

cp "${ROOT_DIR}/assets/${ICON_FILE}" "${DATA_ROOT}/usr/local/${APP_ID}/images/icons/${ICON_FILE}"
cp "${ROOT_DIR}/app/index.html" "${WEBUI_STAGE}/index.html"
cp "${ROOT_DIR}/app/snake.css" "${WEBUI_STAGE}/snake.css"
cp "${ROOT_DIR}/app/snake.js" "${WEBUI_STAGE}/snake.js"
tar --format=gnu -cjf "${DATA_ROOT}/usr/local/${APP_ID}/webui.bz2" -C "${WEBUI_STAGE}" .

cp "${ROOT_DIR}/app/server.py" "${SERVICE_ROOT}/usr/local/${APP_ID}/bin/server.py"
cp "${ROOT_DIR}/app/index.html" "${SERVICE_ROOT}/usr/local/${APP_ID}/web/index.html"
cp "${ROOT_DIR}/app/snake.css" "${SERVICE_ROOT}/usr/local/${APP_ID}/web/snake.css"
cp "${ROOT_DIR}/app/snake.js" "${SERVICE_ROOT}/usr/local/${APP_ID}/web/snake.js"
cp "${DATA_ROOT}/usr/local/${APP_ID}/init.d/${SERVICE_ID}.service" "${SERVICE_ROOT}/etc/systemd/system/${SERVICE_ID}.service"

cat > "${SERVICE_ROOT}/DEBIAN/preinst" <<EOF
#!/bin/sh
set -e
if ! id -u ${SERVICE_USER} >/dev/null 2>&1; then
  useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin ${SERVICE_USER} >/dev/null 2>&1 || true
fi
exit 0
EOF

cat > "${SERVICE_ROOT}/DEBIAN/postinst" <<EOF
#!/bin/sh
set -e
chown -R ${SERVICE_USER}:${SERVICE_USER} /usr/local/${APP_ID}/web /usr/local/${APP_ID}/bin || true
systemctl daemon-reload || true
systemctl enable ${SERVICE_ID}.service || true
systemctl restart ${SERVICE_ID}.service || systemctl start ${SERVICE_ID}.service || true
exit 0
EOF

cat > "${SERVICE_ROOT}/DEBIAN/prerm" <<EOF
#!/bin/sh
set -e
systemctl stop ${SERVICE_ID}.service || true
systemctl disable ${SERVICE_ID}.service || true
exit 0
EOF

cat > "${SERVICE_ROOT}/DEBIAN/postrm" <<EOF
#!/bin/sh
set -e
systemctl daemon-reload || true
exit 0
EOF

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

DATA_DEB="${DIST_DIR}/${DATA_PACKAGE}_${VERSION}_${DEB_ARCH}.deb"
SERVICE_DEB="${DIST_DIR}/${SERVICE_PACKAGE}_${VERSION}_${DEB_ARCH}.deb"
FINAL_TAR="${DIST_DIR}/${APP_ID}_${PLATFORM}.tar.gz"
SHA256_FILE="${DIST_DIR}/SHA256SUMS.txt"

dpkg-deb --build "${DATA_ROOT}" "${DATA_DEB}"
dpkg-deb --build "${SERVICE_ROOT}" "${SERVICE_DEB}"

TMP_TAR_DIR="${BUILD_DIR}/tar"
mkdir -p "${TMP_TAR_DIR}"
cp "${DATA_DEB}" "${TMP_TAR_DIR}/${APP_ID}.deb"
cp "${SERVICE_DEB}" "${TMP_TAR_DIR}/${SERVICE_PACKAGE}.deb"

tar --format=gnu -czf "${FINAL_TAR}" -C "${TMP_TAR_DIR}" .

(
  cd "${DIST_DIR}"
  sha256sum "$(basename "${DATA_DEB}")" "$(basename "${SERVICE_DEB}")" "$(basename "${FINAL_TAR}")" > "${SHA256_FILE}"
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
