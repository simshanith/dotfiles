#!/bin/sh
# Reconcile rtk's Claude Code hook to this machine's choice, on every apply.
#
# The choice lives in a marker file written by `rtk-hook enable` / removed by
# `rtk-hook disable`. This script only re-asserts it -- it never decides.
#
#   marker present  ->  `rtk-hook enable` repairs the wiring if it drifted
#   marker absent   ->  do nothing at all
#
# That asymmetry is deliberate. An earlier draft asserted the hook on every
# apply unconditionally, which would have silently undone `rtk-hook disable` on
# the next `chezmoi apply`. Gating on the marker makes the toggle stick.
#
# Absent marker means "not enabled here", so a fresh machine gets rtk on PATH
# and no hook until it asks for one -- the right default for a fleet that is
# mostly headless. It also means this never *removes* a hook: someone who ran
# `rtk init -g` by hand keeps what they wired until they run `rtk-hook disable`,
# which `rtk-hook status` will point out.
#
# No-ops silently when Claude Code isn't installed.

set -eu

[ -d "$HOME/.claude" ] || exit 0
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/rtk-hook-enabled" ] || exit 0
[ -x "$HOME/bin/rtk-hook" ] || exit 0

# --quiet keeps a clean apply silent; it prints only when it actually repairs.
"$HOME/bin/rtk-hook" enable --quiet
