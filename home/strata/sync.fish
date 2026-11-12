# Folder sync between Strata and the Monstar its "Open in Terminal" opened
# (home/strata/terminal starts that shell with `fish -C 'source …'`).
# - Strata (erebor patch) writes the focused window's folder to
#   $XDG_RUNTIME_DIR/strata/active-folder; a watcher signals this shell, which
#   follows it at the next prompt.
# - A `cd` here moves Strata's focused window there (its sync-navigate action).
# Loops stop on their own: Strata ignores a folder it already shows and this
# shell ignores the folder it is in.
status is-interactive; or return

set -g __strata_sync_file "$XDG_RUNTIME_DIR/strata/active-folder"

function __strata_sync_follow --on-signal SIGUSR1
    test -r "$__strata_sync_file"; or return
    read -l dir <"$__strata_sync_file"
    if test -n "$dir"; and test -d "$dir"; and test "$dir" != "$PWD"
        set -g __strata_sync_following 1
        cd "$dir"
        set -e __strata_sync_following
        commandline -f repaint
    end
end

function __strata_sync_tell --on-variable PWD
    set -q __strata_sync_following; and return
    @tell@ "$PWD" &
    disown
end

@watch@ $fish_pid &
disown
