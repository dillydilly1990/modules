#!/usr/bin/env bash
set -euo pipefail

mapfile -t FONTS <<< "$@"
DEST="/usr/share/fonts/google-fonts"

echo "Installation of google-fonts started"
rm -rf "${DEST}"

for FONT in "${FONTS[@]}"; do
    FONT="${FONT#"${FONT%%[![:space:]]*}"}" # Trim leading whitespace
    FONT="${FONT%"${FONT##*[![:space:]]}"}" # Trim trailing whitespace
    mkdir -p "${DEST}/${FONT}"

    readarray -t "FILE_REFS" < <(
        if output=$(curl -s "https://fonts.google.com/download/list?family=${FONT// /%20}" | tail -n +2); then
            if FILE_REFS=$(echo "$output" | jq -c '.manifest.fileRefs[]' 2>/dev/null); then
                echo "$FILE_REFS"
            fi
        fi
    )

    if [ ${#FILE_REFS[@]} -eq 0 ]; then
        echo "Could not find download information for ${FONT}"
    else
        for FILE_REF in "${FILE_REFS[@]}"; do
            if FILENAME=$(echo "${FILE_REF}" | jq -er '.filename' 2>/dev/null); then
                if URL=$(echo "${FILE_REF}" | jq -er '.url' 2>/dev/null); then
                    echo "Downloading ${FILENAME} from ${URL}"
                    curl "${URL}" -o "${DEST}/${FONT}/${FILENAME##*/}" # everything before the last / is removed to get the filename
                else
                    echo "Failed to extract URLs for: ${FONT}" >&2
                fi
            else
                echo "Failed to extract filenames for: ${FONT}" >&2
            fi
        done
    fi
done

fc-cache -f "${DEST}"
