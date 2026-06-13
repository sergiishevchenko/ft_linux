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

if ! command -v wget &>/dev/null; then
    error "wget is required."
    exit 1
fi

if [ ! -f "$WGET_LIST" ]; then
    error "wget-list.txt not found at $WGET_LIST"
    exit 1
fi

TOTAL=$(wc -l < "$WGET_LIST" | tr -d ' ')
CURRENT=0
FAILED=0

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
    if wget -q --continue --tries=3 --timeout=30 "$url" -P "$SOURCES_DIR" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        FAILED=$((FAILED + 1))
    fi
done < "$WGET_LIST"

echo ""
if [ "$FAILED" -gt 0 ]; then
    warn "$FAILED packages failed. Re-run to retry."
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
        warn "Some checksums failed."
    fi
    popd > /dev/null
fi
