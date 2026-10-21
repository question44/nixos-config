# Upstream's dispatcher accepts a client target but toggle_scratchpad ignores it.
# Honor explicit targets so Umbriel's bidirectional scratchpad navigation ports
# without converting windows into named scratchpads. Untargeted behavior stays
# upstream's default pool toggle.
{ mango }:
mango.overrideAttrs (old: {
  version = "0.18.2";
  __intentionallyOverridingVersion = true; # Source is pinned to the release tag.
  postPatch = (old.postPatch or "") + ''
    substituteInPlace src/dispatch/bind.c --replace-fail \
      'int32_t toggle_scratchpad(const Arg *arg) {' \
      'int32_t toggle_scratchpad(const Arg *arg) {
        if (arg->tc) {
          if (server.selected_monitor && server.selected_monitor->isoverview)
            return 0;
          switch_scratchpad_client_state(arg->tc);
          return 0;
        }'
  '';
})
