#!/usr/bin/env bash

# ComfyUI Docker Startup File v1.0.2 by John Aldred
# http://www.johnaldred.com
# http://github.com/kaouthia

set -e

# --- Force ComfyUI-Manager config (uv off, no file logging, safe DB) ---
# Make sure user dirs exist and are writable (handles Windows bind mounts)
mkdir -p /app/ComfyUI/user /app/ComfyUI/user/default /app/ComfyUI/user/__manager
chown -R "$(id -u)":"$(id -g)" /app/ComfyUI/user || true
chmod -R u+rwX /app/ComfyUI/user || true

CFG_DIR="/app/ComfyUI/user/__manager"
CFG_FILE="$CFG_DIR/config.ini"

DB_DIR="/app/ComfyUI/user/default"
DB_PATH="${DB_DIR}/manager.db"
SQLITE_URL="sqlite:////${DB_PATH}"

mkdir -p "$CFG_DIR"

if [ ! -f "$CFG_FILE" ]; then
  echo "↳ Creating ComfyUI-Manager config.ini (uv OFF, no file logging, DB cache)"
  cat > "$CFG_FILE" <<EOF
[default]
use_uv = False
file_logging = False
db_mode = cache
database_url = ${SQLITE_URL}
security_level = weak
network_mode = public
always_lazy_install = False
bypass_ssl = True
EOF
fi


# --- Prepare custom nodes ---
CN_DIR=/app/ComfyUI/custom_nodes
INIT_MARKER="$CN_DIR/.custom_nodes_initialized"

declare -A REPOS=(
  ["ComfyUI-Manager"]="https://github.com/ltdrdata/ComfyUI-Manager.git"
  ["ComfyUI_essentials"]="https://github.com/cubiq/ComfyUI_essentials.git"
  ["ComfyUI-Crystools"]="https://github.com/crystian/ComfyUI-Crystools.git"
  ["rgthree-comfy"]="https://github.com/rgthree/rgthree-comfy.git"
  ["ComfyUI-KJNodes"]="https://github.com/kijai/ComfyUI-KJNodes.git"
  ["ComfyUI_UltimateSDUpscale"]="https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git"
)

if [ ! -f "$INIT_MARKER" ]; then
  echo "↳ First run: initializing custom_nodes…"
  mkdir -p "$CN_DIR"
  for name in "${!REPOS[@]}"; do
    url="${REPOS[$name]}"
    target="$CN_DIR/$name"
    if [ -d "$target" ]; then
      echo "  ↳ $name already exists, skipping clone"
    else
      echo "  ↳ Cloning $name"
      git clone --depth 1 "$url" "$target"
    fi
  done

  echo "↳ Installing/upgrading dependencies…"
  for dir in "$CN_DIR"/*/; do
    req="$dir/requirements.txt"
    if [ -f "$req" ]; then
      echo "  ↳ pip install --upgrade -r $req"
      python -m pip install --no-cache-dir --upgrade -r "$req"
    fi
  done

  # Create marker file
  touch "$INIT_MARKER"
else
  echo "↳ Custom nodes already initialized, skipping clone and dependency installation."
fi

echo "↳ Launching ComfyUI"
exec "$@"