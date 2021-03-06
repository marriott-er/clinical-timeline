#!/usr/bin/env bash
# dir of bash script http://stackoverflow.com/questions/59895
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# From: https://github.com/tremby/imgur.sh/blob/master/imgur.sh
default_client_id=c9a6efb3d7932fd
client_id="${IMGUR_CLIENT_ID:=$default_client_id}"

function upload {
	curl -s -H "Authorization: Client-ID $client_id" -H "Expect: " -F "image=@$1" https://api.imgur.com/3/image.xml | grep -oe 'https://[a-zA-Z0-9./]*'
	# The "Expect: " header is to get around a problem when using this through
	# the Squid proxy. Not sure if it's a Squid bug or what.
}

# patient view screenshot
screenshot_error_count=0
for testdata in $(echo ${DIR}/data/data*.json); do
    for view in advanced simple; do
        screenshot_png="${DIR}/screenshots/index_html_$(basename $testdata .json)_${view}.png"

        phantomjs --ignore-ssl-errors=true ${DIR}/make_screenshots.js \
            "${DIR}/../index.html?test=$(basename $testdata .json)?view=${view}" \
            $screenshot_png \
            50
        
        # make sure screenshot is still the same as the one in the repo, if not upload
        # the image
        git diff --quiet -- $screenshot_png
        if [[ $? -ne 0 ]]; then
            screenshot_error_count=$(($screenshot_error_count + 1))
            echo "screenshot differs see:" && upload "${screenshot_png}"
        fi
    done
done

#examples.html screenshots
screenshot_png="${DIR}/screenshots/examples.png"
phantomjs --ignore-ssl-errors=true ${DIR}/make_screenshots.js \
    "${DIR}/../examples.html" \
    $screenshot_png \
    50
# make sure screenshot is still the same as the one in the repo, if not upload
# the image
git diff --quiet -- $screenshot_png
if [[ $? -ne 0 ]]; then
    screenshot_error_count=$(($screenshot_error_count + 1))
    echo "screenshot differs see:" && upload "${screenshot_png}"
fi

if [[ $screenshot_error_count -gt 0 ]]; then
    echo "${screenshot_error_count} SCREENSHOT TESTS FAILED"
    exit 1
else
    exit 0
fi
