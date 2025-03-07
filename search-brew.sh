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

# Future work:
# - [ ] Note if package is installed already
#     - (Would probably involve rewrite in python)

function installed_json() {
  # Run "brew ls -1 formula" (or cask) and turn it into an object like
  # {"bash": "bash", "screen": "screen"}
  if ! [ "$1" = "formula" ] || [ "$1" = "cask" ]; then
    echo "Usage: one of:"
    echo "  installed_json formula"
    echo "  installed_json cask"
    return
  fi
  brew ls -1 "--${1}" | jq -R . | jq --slurp 'INDEX(.)'
}

echo Formulas
echo ========
jq -rn 'input as $formulae
  | input as $installed
  | $formulae
  | .[]
  # Search name, description, website
  | select(
    [.name, .desc, .homepage]
    | join(" ")
    | ascii_downcase
    | test("'"${*}"'" | ascii_downcase)?
    )
  # Output
  | [
    .name + (
      # Add "✓" for installed packages
      if (.name | in($installed))
        then " ✓"
        else ""
      end
      ),
    .desc,
    .homepage,
    ""
    ]
  | join("\n")' formula.json <(installed_json formula)

echo

echo Casks
echo =====
jq -rn 'input as $casks
  | input as $installed
  | $casks
  | .[]
  # search package name, human name, description, website
  | select(
    [.token, .name[0], .desc, .homepage]
    | join(" ")
    | ascii_downcase
    | test("'"${*}"'" | ascii_downcase)?
    )
  # Output
  | [
    .token + (
      # Add "✓" for installed packages
      if (.token | in($installed))
        then " ✓"
        else ""
      end
      ),
    .name[0],
    .desc,
    .homepage,
    ""
    ]
  | join("\n")' cask.json <(installed_json cask)

