{ writeShellApplication, jq }:
# Shared by the Noctalia bar button and the dashboard control API. Umbriel
# itself comes from the caller's PATH, matching the other session helpers.
writeShellApplication {
  name = "umbriel-display-mode";
  runtimeInputs = [ jq ];
  text = builtins.readFile ../home/umbriel/display-mode;
}
