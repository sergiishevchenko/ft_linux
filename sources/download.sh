#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCES_DIR="$SCRIPT_DIR"
WGET_LIST="$SCRIPT_DIR/wget-list.txt"
MD5SUMS="$SCRIPT_DIR/md5sums.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[-]${NC} $*"; }

WGET_OPTS=(--prefer-family=IPv4 --continue --tries=5 --timeout=120 --waitretry=5)

if ! command -v wget &>/dev/null; then
    error "wget is required."
    exit 1
fi

if [ ! -f "$WGET_LIST" ]; then
    error "wget-list.txt not found at $WGET_LIST"
    exit 1
fi

TOTAL=$(grep -cve '^[[:space:]]*$' "$WGET_LIST" || true)
CURRENT=0
FAILED=0
FAILED_NAMES=()

log "Downloading $TOTAL packages to $SOURCES_DIR"
echo ""

while IFS= read -r url; do
    [ -z "$url" ] && continue
    CURRENT=$((CURRENT + 1))
    FILENAME=$(basename "$url")

    if [ -f "$SOURCES_DIR/$FILENAME" ]; then
        echo -e "  [${CURRENT}/${TOTAL}] ${YELLOW}SKIP${NC} $FILENAME"
        continue
    fi

    echo -ne "  [${CURRENT}/${TOTAL}] Downloading $FILENAME... "
    if wget "${WGET_OPTS[@]}" -q "$url" -O "$SOURCES_DIR/$FILENAME"; then
        echo -e "${GREEN}OK${NC}"
    else
        rm -f "$SOURCES_DIR/$FILENAME"
        echo -e "${RED}FAIL${NC}"
        FAILED=$((FAILED + 1))
        FAILED_NAMES+=("$FILENAME")
    fi
done < "$WGET_LIST"

echo ""
if [ "$FAILED" -gt 0 ]; then
    warn "$FAILED packages failed. Re-run to retry:"
    for f in "${FAILED_NAMES[@]}"; do
        echo "    - $f"
    done
else
    log "All packages downloaded!"
fi

if [ -f "$MD5SUMS" ]; then
    echo ""
    log "Verifying checksums..."
    pushd "$SOURCES_DIR" > /dev/null
    if md5sum -c "$MD5SUMS" 2>/dev/null; then
        log "All checksums verified!"
    else
        warn "Some checksums failed (missing files also count as failed)."
    fi
    popd > /dev/null
fi

exit "$FAILED"
