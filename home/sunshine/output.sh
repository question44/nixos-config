# Executed by the Nix-built sunshine-output helper.
set -euo pipefail

stream_output=sunshine
if [[ ${XDG_CURRENT_DESKTOP:-} == mango ]]; then
  case "${1:-}" in
    create)
      width=${SUNSHINE_CLIENT_WIDTH:-1920}
      height=${SUNSHINE_CLIENT_HEIGHT:-1080}
      fps=${SUNSHINE_CLIENT_FPS:-60}
      [[ "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ && "$fps" =~ ^[0-9]+$ ]] || exit 1
      if ! wlr-randr --json | jq -e --arg name "$stream_output" \
        'any(.[]; .name == $name)' >/dev/null; then
        mmsg dispatch "create_virtual_output,$stream_output"
      fi
      # Place the stream beyond existing outputs, preserving their layout.
      right=$(mmsg get all-monitors | jq --arg name "$stream_output" \
        '[.monitors[] | select(.name != $name) | .x + .width] | max // 0')
      wlr-randr --output "$stream_output" --on --custom-mode "${width}x${height}@${fps}Hz" \
        --scale 1 --pos "$right,0"
      ;;
    remove)
      # Keep this output alive between streams. Mango 0.18.2 can abort in
      # output_manager_apply_or_test when disabling/re-enabling outputs, and
      # destroy_all_virtual_output would also remove the ambilight output.
      :
      ;;
    *) echo 'Usage: sunshine-output create|remove' >&2; exit 2 ;;
  esac
  exit 0
fi
export UMBRIEL_SOCKET="${UMBRIEL_SOCKET:-${XDG_RUNTIME_DIR:?}/umbriel-${WAYLAND_DISPLAY:-wayland-0}.sock}"

case "${1:-}" in
  create)
    width=${SUNSHINE_CLIENT_WIDTH:-1920}
    height=${SUNSHINE_CLIENT_HEIGHT:-1080}
    fps=${SUNSHINE_CLIENT_FPS:-60}
    [[ "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ && "$fps" =~ ^[0-9]+$ ]] || exit 1
    # Leave an existing stream output alone rather than displacing its windows.
    if ! umbriel outputs --json | jq -e --arg name "$stream_output" \
      'any(.[]; .name == $name)' >/dev/null; then
      umbriel output-create "$stream_output" "${width}x${height}@${fps}"
    fi
    ;;
  remove)
    # Allow the application's undo action to finish closing its windows.
    for ((attempt=0; attempt<25; attempt++)); do
      windows=$(umbriel windows --json)
      if ! jq -e --arg prefix "$stream_output:" \
        'any(.[]; .workspace | startswith($prefix))' <<<"$windows" >/dev/null; then
        break
      fi
      sleep 0.2
    done
    # Explicitly relocate survivors, clearing their remembered output affinity.
    destination=$(umbriel workspaces --json | jq -r --arg output "$stream_output" \
      '[.[] | select(.output != $output and .output != "ambilight" and .active)]
       | sort_by(.focused | not) | first | if . then "\(.name)/\(.output)" else empty end')
    mapfile -t survivors < <(umbriel windows --json | jq -r --arg prefix "$stream_output:" \
      '.[] | select(.workspace | startswith($prefix)) | .id')
    for window in "${survivors[@]}"; do
      [[ -n "$destination" ]] || { echo 'No destination for stream windows' >&2; exit 1; }
      umbriel msg "window-focus:$window"
      umbriel msg "window-move-to-workspace-silent:$destination"
    done
    if umbriel outputs --json | jq -e --arg name "$stream_output" \
      'any(.[]; .name == $name)' >/dev/null; then
      umbriel output-destroy "$stream_output"
    fi
    ;;
  *) echo 'Usage: sunshine-output create|remove' >&2; exit 2 ;;
esac
