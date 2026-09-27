# SwayP Greeter

Graphical greetd frontend for SwayP.

It runs as the `greeter` user and communicates with greetd through its Unix
socket. Cage provides the Wayland compositor and Quickshell renders the UI.

## Safe rollout

`tuigreet` remains the fallback until this has been tested from a spare VT.

Do not replace `/etc/greetd/config.toml` before validating the graphical
greeter on a real VT.
