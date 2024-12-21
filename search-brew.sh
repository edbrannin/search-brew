#!/bin/bash

# https://stackoverflow.com/a/59643790
file_age() {
    local filename=$1
    echo $(( $(date +%s) - $(date -r "$filename" +%s) ))
}
is_stale() {
    local filename=$1
    local max_days=7
    local max_seconds=$(( max_days * 24 * 60 * 60 ))
    [ "$(file_age "$filename")" -gt $(( max_seconds )) ]
}

function get_json() {
  local url="https://formulae.brew.sh/api/$1.json"
  local filename="${1}.json"

  if [ ! -r "$filename" ] || is_stale "$filename"; then
    echo "Downloading $filename"
    curl "$url" > "$filename"
  fi
}

get_json formula
get_json cask

echo Formulas
echo ========
jq -r '.[] | select([.name, .desc, .homepage] | join(" ") | ascii_downcase | test("'"${*}"'" | ascii_downcase)?) | [.name, .desc, .homepage, ""] | join("\n")' < formula.json

echo Casks
echo =====
jq -r '.[] | select([.token, .name[0], .desc, .homepage] | join(" ") | ascii_downcase | test("'"${*}"'" | ascii_downcase)?) | [.token, .name[0], .desc, .homepage, ""] | join("\n")' < cask.json

