#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"; }
warn()  { echo -e "${YELLOW}[$(date +%H:%M:%S)] WARN:${NC} $*"; }
error() { echo -e "${RED}[$(date +%H:%M:%S)] ERROR:${NC} $*"; exit 1; }

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root."
    fi
}

require_cmd() {
    command -v "$1" &>/dev/null || error "Required command not found: $1"
}

require_var() {
    local name="$1"
    if [ -z "${!name:-}" ]; then
        error "Required variable not set: $name"
    fi
}

require_dir() {
    [ -d "$1" ] || error "Directory not found: $1"
}

make_jobs() {
    echo "-j$(nproc 2>/dev/null || echo 2)"
}

extract_src() {
    local pattern="$1"
    local sources_dir="${SOURCES:-/sources}"
    local archive

    archive=$(ls "$sources_dir"/$pattern 2>/dev/null | head -1)
    [ -n "$archive" ] || error "Source not found: $sources_dir/$pattern"

    cd "$sources_dir"
    case "$archive" in
        *.tar.xz|*.txz) tar -xf "$archive" ;;
        *.tar.gz|*.tgz) tar -xf "$archive" ;;
        *.tar.bz2)      tar -xf "$archive" ;;
        *)              tar -xf "$archive" ;;
    esac
}

enter_src() {
    local dirname="$1"
    local sources_dir="${SOURCES:-/sources}"
    cd "$sources_dir"
    cd ${dirname}* || error "Cannot enter source dir matching: $dirname"
}

clean_src() {
    local dirname="$1"
    local sources_dir="${SOURCES:-/sources}"
    cd "$sources_dir"
    rm -rf ${dirname}*
}

build_autotools() {
    local name="$1"
    shift

    log "========== Building $name =========="
    extract_src "${name}-*"
    enter_src "$name"
    ./configure "$@"
    make $(make_jobs)
    make install
    clean_src "$name"
    log "$name complete."
}

replace_placeholder() {
    local file="$1"
    local placeholder="$2"
    local value="$3"
    sed -i "s|${placeholder}|${value}|g" "$file"
}

mark_done() {
    local state_file="${STATE_FILE:-/tmp/ft_linux_build.state}"
    local pkg="$1"
    echo "$pkg" >> "$state_file"
}

is_done() {
    local state_file="${STATE_FILE:-/tmp/ft_linux_build.state}"
    local pkg="$1"
    [ -f "$state_file" ] && grep -qx "$pkg" "$state_file"
}

run_once() {
    local pkg="$1"
    shift
    if is_done "$pkg"; then
        log "SKIP $pkg (already done)"
        return 0
    fi
    "$@"
    mark_done "$pkg"
}
