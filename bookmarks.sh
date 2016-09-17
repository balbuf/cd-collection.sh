#!/bin/sh

# use parens instead of braces to allow interal helper functions
function bm() (

# directory to store bookmarks - defaults to home dir
local dir="${BOOKMARK_DIR:-$HOME/.bookmarks}"
local target=''
mkdir -p "$dir"

# basic usage instructions
if [[ -z "$@" ]]; then
	cat <<-'DOG'
		usage: bm [--] <target>
		       bm <command> [<args>]

		COMMANDS

		   add    Add a new bookmark without overwriting an existing one
		   go     Go to the given target
		   help   Display this message
		   set    Add or overwrite an existing bookmark
		   show   Show the target path of a given bookmark
		   rm     Remove an existing bookmark

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

	# remove an existing bookmark
	'rm' | 'remove')
		# does it exist?
		test_target "$2" || return $?
		# is it a subdir or file of the actual bookmark?
		if ! test_name "$2" &> /dev/null; then
			echo "Error: Target '$2' cannot be removed." >&2
			return 2
		fi
		rm "$dir/$2" || return $?
		echo "Success: Removed target '$2' pointing to $PWD"
	;;

	# explicitly go to a bookmark, in case a reserved word is used
	'go' | '--')
		target="$2"
	;;

	'help')
		bm
	;;

	# default - assumes the arg is a bookmark
	*)
		target="$1"
	;;
esac

# no target? we have completed some other action successfully
[[ -z "$target" ]] && return 0

# test that the target even exists
test_target "$target" || return $?

# go to the physical (-P) location that the symlink points to
cd -P "$dir/$target"

) # end bm()
