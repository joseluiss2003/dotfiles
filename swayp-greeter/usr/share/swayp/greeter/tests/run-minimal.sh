#!/bin/sh
set -eu

export XKB_DEFAULT_LAYOUT=es
export XCURSOR_SIZE=24

exec cage -s -- /usr/bin/qs -c /usr/share/swayp/greeter/tests
