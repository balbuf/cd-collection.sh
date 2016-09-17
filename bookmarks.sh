#!/bin/sh
# todo: tab complete
# todo: list all bms
# todo: allow 2nd arg to add a sub dir (or slash after bookmark name)
function bm() {
  map=~/.bookmarks
  # add a new bookmark?
  if [[ "$1" == "add" && -n "$2" ]]; then
    # todo - check for existing entry
    echo "$2:$PWD" >> "$map"
    echo "Success: Added bookmark '$2' for $PWD"
    return 0
  fi # todo add delete option
  dest="$(grep "$1:" "$map" 2>/dev/null | cut -d ':' -f 2)"
  if [[ -z "$dest" ]]; then
    echo "No bookmark entry for $1"
    return 1
  fi
  cd "$dest/$2"
}
