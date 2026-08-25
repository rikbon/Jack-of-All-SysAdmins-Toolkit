#!/usr/bin/env bash

set -Eeuo pipefail

VERSION=""
OUTPUT_DIRECTORY="${PWD}/Release"

usage() {
    printf 'Usage: %s [-v version] [-o output-directory]\n' "$0"
}

while getopts ':v:o:h' option; do
    case "$option" in
        v) VERSION="$OPTARG" ;;
        o) OUTPUT_DIRECTORY="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "$VERSION" ]]; then
    VERSION="$(<"${REPOSITORY_ROOT}/VERSION")"
fi
if [[ -z "$VERSION" || ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf 'Invalid version in VERSION: %s\n' "$VERSION" >&2
    exit 2
fi
STAGING_ROOT="${OUTPUT_DIRECTORY}/.staging"

copy_if_exists() {
    local source="$1"
    local destination="$2"
    if [[ -e "$source" ]]; then
        mkdir -p "$(dirname "$destination")"
        cp -R "$source" "$destination"
    fi
}

rm -rf "$STAGING_ROOT"
mkdir -p "$OUTPUT_DIRECTORY" "$STAGING_ROOT"

for platform in Windows Linux macOS; do
    platform_source="${REPOSITORY_ROOT}/${platform}"
    archive_root="${STAGING_ROOT}/${platform}/SysAdminToolbox_${platform}"
    zip_path="${OUTPUT_DIRECTORY}/SysAdminToolbox_${platform}_v${VERSION}.zip"

    if [[ ! -d "$platform_source" ]]; then
        printf 'Skipping %s: source directory not found at %s\n' "$platform" "$platform_source" >&2
        continue
    fi

    mkdir -p "$archive_root"
    copy_if_exists "${REPOSITORY_ROOT}/README.md" "${archive_root}/README.md"
    copy_if_exists "${REPOSITORY_ROOT}/LICENSE.md" "${archive_root}/LICENSE.md"
    copy_if_exists "${REPOSITORY_ROOT}/RELEASE_NOTES.md" "${archive_root}/RELEASE_NOTES.md"
    copy_if_exists "${REPOSITORY_ROOT}/VERSION" "${archive_root}/VERSION"
    copy_if_exists "${REPOSITORY_ROOT}/docs" "${archive_root}/docs"
    copy_if_exists "$platform_source" "${archive_root}/${platform}"

    if command -v zip >/dev/null 2>&1; then
        (cd "${STAGING_ROOT}/${platform}" && zip -qr "$zip_path" "SysAdminToolbox_${platform}")
    elif command -v 7z >/dev/null 2>&1; then
        (cd "${STAGING_ROOT}/${platform}" && 7z a -tzip "$zip_path" "SysAdminToolbox_${platform}" >/dev/null)
    else
        printf 'Neither zip nor 7z is available; cannot create %s\n' "$zip_path" >&2
        rm -rf "$STAGING_ROOT"
        exit 1
    fi

done

rm -rf "$STAGING_ROOT"
printf 'Build complete. Archives available in %s\n' "$OUTPUT_DIRECTORY"
