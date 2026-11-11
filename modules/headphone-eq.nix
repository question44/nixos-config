# Headphone EQ: a PipeWire filter-chain sink that applies a parametric EQ
# profile and plays into a fixed output device. The default profile is the
# FiiO FT1 "Super review" curve the user runs in SoundSource on the Mac.
# The DAC also drives speakers, so the EQ is off unless chosen: `headphone-eq
# on|off|toggle|set PRESET` swaps the default sink between the EQ and the DAC;
# `status` prints the active preset or "off", `list` the presets (the Noctalia
# janzon/toggles plugin calls it).
{ ... }:
{
  flake.modules.nixos.headphone-eq =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.headphoneEq;
      kinds = {
        peak = "bq_peaking";
        lowshelf = "bq_lowshelf";
        highshelf = "bq_highshelf";
      };
      # A high shelf at 0 Hz is a flat gain: the profile's preamp.
      filters = [
        {
          type = "highshelf";
          freq = 0;
          gain = cfg.preamp;
          q = 1.0;
        }
      ]
      ++ cfg.bands;
      node = i: f: {
        type = "builtin";
        name = "eq${toString i}";
        label = kinds.${f.type};
        control = {
          Freq = f.freq;
          Q = f.q;
          Gain = f.gain;
        };
      };
      n = builtins.length filters;
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "headphone-eq";
          runtimeInputs = [
            pkgs.pipewire
            pkgs.wireplumber
            pkgs.jq
          ];
          text = ''
            eq=effect_input.headphone_eq
            dac=${lib.escapeShellArg cfg.target}

            preset=${lib.escapeShellArg cfg.name}

            id_of() {
              pw-dump | jq -r --arg n "$1" \
                'first(.[] | select(.info.props."node.name" == $n) | .id) // empty'
            }
            # The active preset's name, or "off" when the plain DAC is default.
            state() {
              if wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null |
                grep -q "node.name = \"$eq\""; then
                echo "$preset"
              else
                echo off
              fi
            }
            set_default() {
              local id
              id=$(id_of "$1")
              if [ -z "$id" ]; then
                echo "headphone-eq: sink $1 not found" >&2
                exit 1
              fi
              wpctl set-default "$id"
            }

            case "''${1:-status}" in
              on) set_default "$eq" ;;
              off) set_default "$dac" ;;
              toggle)
                if [ "$(state)" = off ]; then set_default "$eq"; else set_default "$dac"; fi
                ;;
              set)
                case "''${2:-}" in
                  off) set_default "$dac" ;;
                  "$preset") set_default "$eq" ;;
                  *)
                    echo "headphone-eq: unknown preset ''${2:-}" >&2
                    exit 2
                    ;;
                esac
                ;;
              list)
                echo "$preset"
                exit 0
                ;;
              status) ;;
              *)
                echo "usage: headphone-eq [on|off|toggle|status|list|set PRESET|set off]" >&2
                exit 2
                ;;
            esac
            state
          '';
        })
      ];

      services.pipewire.extraConfig.pipewire."90-headphone-eq" = {
        "context.modules" = [
          {
            name = "libpipewire-module-filter-chain";
            args = {
              "node.description" = "${cfg.name} EQ";
              "media.name" = "${cfg.name} EQ";
              "filter.graph" = {
                nodes = lib.imap0 node filters;
                links = map (i: {
                  output = "eq${toString i}:Out";
                  input = "eq${toString (i + 1)}:In";
                }) (lib.range 0 (n - 2));
              };
              "audio.channels" = 2;
              "audio.position" = [
                "FL"
                "FR"
              ];
              "capture.props" = {
                "node.name" = "effect_input.headphone_eq";
                "media.class" = "Audio/Sink";
                # Below the hardware sinks: never picked as default by itself.
                "priority.session" = 100;
                "priority.driver" = 100;
              };
              "playback.props" = {
                "node.name" = "effect_output.headphone_eq";
                "node.passive" = true;
                "target.object" = cfg.target;
                "node.dont-fallback" = true;
                "node.linger" = true;
              };
            };
          }
        ];
      };
    };
}
