#!/bin/bash
# restore.sh - review quarantined files
# Usage: restore.sh dir malicious_dir

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHITELIST="$SCRIPT_DIR/whitelist.txt"

if [ $# -ne 2 ]; then
    echo "Usage: $0 dir malicious_dir" >&2
    exit 1
fi

DIR="$1"; MAL_DIR="$2"

if [ ! -d "$MAL_DIR" ]; then
    echo "No malicious files to review."
    exit 0
fi

shopt -s nullglob dotglob

while true; do
    files=()
    for f in "$MAL_DIR"/*; do
        [ -f "$f" ] && files+=("${f##*/}")
    done

    if [ "${#files[@]}" -eq 0 ]; then
        echo "No malicious files to review."
        exit 0
    fi

    echo
    echo "Quarantined files:"
    for i in "${!files[@]}"; do
        echo "  $((i + 1))) ${files[$i]}"
    done
    read -r -p "Pick a file number (q to quit): " choice || exit 0

    [ "$choice" = "q" ] && exit 0
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#files[@]}" ]; then
        echo "Invalid choice."
        continue
    fi
    name="${files[$((choice - 1))]}"

    echo "Selected: $name"
    echo "  1) Restore to $DIR (false positive)"
    echo "  2) Permanently delete (genuinely malicious)"
    echo "  3) Leave as-is and go back to the list"
    read -r -p "Option: " opt || exit 0

    case "$opt" in
        1)
            mkdir -p "$DIR"
            mv -- "$MAL_DIR/$name" "$DIR/$name"
            touch "$WHITELIST"
            grep -Fxq -- "$name" "$WHITELIST" || echo "$name" >> "$WHITELIST"
            echo "Restored $name to $DIR."
            ;;
        2)
            rm -f -- "$MAL_DIR/$name"
            echo "$name permanently deleted."
            ;;
        3) ;;
        *) echo "Invalid option." ;;
    esac
done

