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

# test the symlink name when adding a new one
function test_name() {
	# symlink name cannot contain a slash
	if [[ "$1" == *\/* ]]; then
		echo "Error: Bookmark name cannot contain a forward slash." >&2
		return 2
	fi
}

# does the target exist?
function test_target() {
	if [[ ! -d "$dir/$1" ]]; then
		echo "Error: Target '$1' does not exist." >&2
		return 2
	fi
}

# what command are we running?
case "$1" in
	# create a new bookmark or overwrite existing
	'set')
		test_name "$2" || return $?
		# attempt to create the symlink
		ln -sfn "$PWD" "$dir/$2" || return $?
		echo "Success: Set '$2' pointing to $PWD"
	;;

	# create a new bookmark without overwriting
	'add')
		test_name "$2" || return $?
		# does the target already exist?
		if test_target "$2" &> /dev/null; then
			echo "Error: Target '$2' already exists." >&2
			return 2
		fi
		ln -s "$PWD" "$dir/$2" || return $?
		echo "Success: Added '$2' pointing to $PWD"
	;;

	# show the destination of an existing bookmark
	'show')
		test_target "$2" || return $?
		readlink "$dir/$2"
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
test_target "$bm" || return $?

# go to the physical (-P) location that the symlink points to
cd -P "$dir/$bm"
