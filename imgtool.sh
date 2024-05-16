#!/bin/bash

# WARNING: Not safe for public use! Created for the author's benefit.
# Assumes:
# - Filenames and directory structure follows the project standard.
# - Correct png images are fed in
# - ImageMagick and ExifToll executables are available


# Minimal check for input file(s)
if [ -z "$1" ]; then
    echo 'Missing filename. Provide at least one png image to process.'
    exit
fi



# Set Document mode to null ('') for normal program images,
#   or the folder prefix for document images (e.g. 'docs')

doc_mode='doc/images/icons/callouts'


if [[ "${doc_mode}" == '' ]]; then
    commit_msg=$(printf '📦 Program graphics (compiled or included with software):')
else
    commit_msg=$(printf '📖 Documentation only artwork (distributed outside a program):')
fi



# Generate visual hash
function vis_hash {
    local img_file="$1"

    vis_rgb="$(magick "${img_file}" -strip -depth 16 -background "#cafe0001c0de" -flatten PPM:- \
    | shasum --algorithm 256 --binary \
    | head -c 64)"

    vis_alpha="$(magick "${img_file}" -strip -depth 16 -alpha extract PPM:- \
    | shasum --algorithm 256 --binary \
    | head -c 64)"

    echo "${vis_rgb}-${vis_alpha}"
}

# Compare the visual hash of two files
function vis_a_vis {
    local img_one="$1"
    local img_two="$2"

    hash_one=$(vis_hash "${img_one}")
    hash_two=$(vis_hash "${img_two}")

    if [[ "${hash_one}" == "${hash_two}" ]]; then
        echo "${hash_one}"
        return 0
    else
        echo 'FAIL'
        return 1
    fi
}

# Report the size in bytes for a 'kpacked' file
function kpack_size {
    # LZMA to approximate 'kpack' but with higher compression settings
    xz -q --format=raw -9 --extreme --stdout "$1" | wc -c | tr -d '[:space:]'
}



#  Iterate through files

while (( "$#" )); do

    #  Check the file exists or skip
    if [[ ! -f "$1" ]]; then
        echo 'WARNING! Image file is not valid.'
        shift # Get the next parameter
        continue
    fi
    # TODO: Check file validity - PNG, etc.

    original_file="${1%.*}"'-OG.png'
    #  Check the original 'OG' file exists or skip
    if [[ ! -f "${original_file}" ]]; then
        echo 'WARNING! Original image file not found.'
        shift # Get the next parameter
        continue
    fi

    # Ensure image file permissions are set correctly (non-executable)
    chmod 644 "$1"

    img_name="$( basename -s .png "$1" )" # e.g. "image1"
    echo ''
    echo 'Processing: ' "${img_name}"
    if [[ "${doc_mode}" == '' ]]; then
        commit_msg=$(printf '%s\n- `%s` slimmed' "${commit_msg}" "${img_name}")
    else
        commit_msg=$(printf '%s\n- `%s/%s` slimmed' "${commit_msg}" "${doc_mode}" "${img_name}")
    fi

    # Check that the visible pixels are identical in the original
    #   and optimized images
    hash_check='FAIL'
    hash_check=$(vis_a_vis "$1" "${original_file}")
    if [[ "${hash_check}" == 'FAIL' ]]; then
        echo 'WARNING! Visual Hashes do not match.'
        vis_hash "$1"
        vis_hash "${original_file}"
        shift # Get the next parameter
        continue
    else
        echo 'Pass - Images are identical.'
    fi

    # Determine bytes saved with optimization
    new_size=$(stat -f %z "$1")
    old_size=$(stat -f %z "${original_file}")
    bytes_saved=0
    ((bytes_saved=old_size-new_size))
    pct_saved=$(echo "scale=2; (${bytes_saved} * 100) / ${old_size}" | bc)
    commit_msg=$(printf '%s %i bytes /' "${commit_msg}" "${bytes_saved}")

    # File size differences after LZMA to approximate 'kpack' container
    # High compression settings are used to give a worst case for bytes savings
    new_size="$(kpack_size "$1")"
    old_size="$(kpack_size "${original_file}")"
    bytes_saved=0
    ((bytes_saved=old_size-new_size))
    commit_msg=$(printf '%s ~%i kpacked /' "${commit_msg}" "${bytes_saved}")
    # TODO: Check for file expansion and issue warning

    # Add Percentage saving to the commit message (to 2 significant figures)
    commit_msg=$(printf '%s ~%.2g%% saving.' "${commit_msg}" "${pct_saved}")

    # Check for changes to the png color mode type and channel depth
    #   but skip if images are for documentation - as these should render fine
    if [[ "${doc_mode}" == '' ]]; then
        new_mode="$(exiftool "$1" \
            | grep 'Color Type' | cut -d ':' -f 2 | tr -d '[:space:]'\
            | sed 's/withAlpha/A/')"
        old_mode="$(exiftool "${original_file}" \
            | grep 'Color Type' | cut -d ':' -f 2 | tr -d '[:space:]'\
            | sed 's/withAlpha/A/')"
        if [[ "${new_mode}" != "${old_mode}" ]]; then
            echo 'Note: color mode was modified!'
            commit_msg=$(printf '%s Note: Color mode changed %s>%s.' "${commit_msg}" "${old_mode}" "${new_mode}")
        fi
        new_depth="$(exiftool "$1" \
            | grep 'Bit Depth' | cut -d ':' -f 2 | tr -d '[:space:]')"
        old_depth="$(exiftool "${original_file}" \
            | grep 'Bit Depth' | cut -d ':' -f 2 | tr -d '[:space:]')"
        if [[ "${new_depth}" != "${old_depth}" ]]; then
            echo 'Note: color depth was modified.'
            commit_msg=$(printf '%s Note: Color depth changed %s>%s.' "${commit_msg}" "${old_depth}" "${new_depth}")
        else
            echo "Color mode: ${new_mode}. Color depth: ${new_depth}."
        fi
    fi

    # Move the original file to Trash
    mv "${original_file}"  ~/.Trash

    # Advance to next image file provided
    shift
done

echo ''
echo '---'
echo ''
echo 'Optimize png files for `x/y`'
echo ''
echo 'Lossless optimization of png image files, using `pngslim` and other tools.'
echo ''
echo "${commit_msg}"
echo ''
echo ''
echo '---'
echo ''
echo '...Finished :)'
echo ''
exit
