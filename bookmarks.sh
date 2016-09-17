#!/bin/sh

# directory to store bookmarks - defaults to home dir
dir="${BOOKMARK_DIR:-$HOME/.bookmarks}"
mkdir -p "$dir"

# basic usage instructions
if [[ -z "$@" ]]; then
	cat <<-'DOG'
		Usage instructions:
	DOG
	return 1
fi

case "$1" in
	# create a new bookmark or overwrite existing
	'set')
		# symlink name cannot contain a slash
		if [[ "$2" == *\/* ]]; then
			echo "Bookmark name cannot contain a forward slash" >&2
			return 2
		fi
		# attempt to create the symlink
		ln -sfn "$PWD" "$dir/$2" || return $?
		echo "Success: Added '$2' pointing to $PWD"
	;;

	# explicitly go to a bookmark, in case a reserved word is used
	'go')
		bm="$2"
	;;

	# default - assumes the arg is a bookmark
	*)
		bm="$1"
	;;
esac

# no bookmark? we have completed some other action successfully
[[ -z "$bm" ]] && return 0

# go to the destination, if it exists
target="$dir/$bm"
# does the target exist?
if [[ ! -d "$target" ]]; then
	echo "Target '$bm' does not exist." >&2
	return 2
fi

# go to the physical (-P) location that the symlink points to
cd -P "$target"
