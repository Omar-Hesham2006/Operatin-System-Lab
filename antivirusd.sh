#!/bin/bash

FLAGGED_EXTENSIONS=(.exe .bat .vbs .scr .ps1)
FLAGGED_KEYWORDS=(virus trojan malware worm ransomware)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHITELIST="$SCRIPT_DIR/whitelist.txt"
LAST="directory-info.last"
NEW="directory-info.new"

if [ $# -ne 3 ]; then
    echo "Usage: $0 dir malicious_dir interval-secs" >&2
    exit 1
fi

DIR="$1"; MAL_DIR="$2"; INTERVAL="$3"

if [ ! -d "$DIR" ]; then
    echo "Error: '$DIR' is not a directory." >&2
    exit 1
fi
mkdir -p "$MAL_DIR" || exit 1
KEYWORD_ARGS=()
for k in "${FLAGGED_KEYWORDS[@]}"; do KEYWORD_ARGS+=(-e "$k"); done

is_whitelisted() {
    [ -f "$WHITELIST" ] && grep -Fxq -- "$1" "$WHITELIST"
}

is_malicious() {
    local ext lower="${2,,}"
    for ext in "${FLAGGED_EXTENSIONS[@]}"; do
        [[ "$lower" == *"$ext" ]] && return 0
    done
    grep -qiaF "${KEYWORD_ARGS[@]}" -- "$1" 2>/dev/null
}

scan() {
    shopt -s nullglob dotglob
    local f name
    for f in "$DIR"/*; do
        [ -f "$f" ] || continue
        name="${f##*/}"
        is_whitelisted "$name" && continue
        if is_malicious "$f" "$name"; then
            echo "$f is malicious and it is DELETED"
            cp -- "$f" "$MAL_DIR/$name" && rm -f -- "$f"
        fi
    done
}

trap 'echo "antivirusd stopped."; exit 0' INT TERM

if [ ! -f "$LAST" ]; then
    scan
    ls -l "$DIR" > "$LAST"
fi

while true; do
    sleep "$INTERVAL" & wait $!
    ls -l "$DIR" > "$NEW"
    if ! cmp -s "$LAST" "$NEW"; then
        scan
        cp "$NEW" "$LAST"
    fi
done
