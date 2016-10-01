#!/bin/sh

function cdc() {

# basic usage instructions
if [[ -z "$@" || "$1" == 'help' ]]; then
	cat <<-'DOG'
		usage: cdc [--] <target>
		       cdc <command> [<args>]

		COMMANDS

		   add    Add a new target without overwriting an existing one
		   get    Get the path of a given target
		   go     Go to the given target
		   help   Display this message
		   ls     List all existing targets
		   set    Add or overwrite an existing target
		   show   Show any targets pointing to the current directory
		   rm     Remove an existing target

	DOG
	# test whether we ran the help command to determine what exit status to use
	[[ "$1" == 'help' ]]
	return $?
fi

# directory to store bookmarks - defaults to home dir
local dir="${CD_COLLECTION:-$HOME/.cdcollection}"
local command="$1"

# what command are we running?
case "$command" in
	# create a new bookmark or overwrite existing
	'set' | 'add')
		# check the name format
		if [[ "$2" == *\/* ]]; then
			echo 'Error: Target name cannot contain a forward slash.' >&2
			return 2
		fi

		# make sure dir exists
		mkdir -p "$dir"

		# attempt to add or overwrite the symlink
		if [[ "$command" == 'set' ]]; then
			ln -sfn "$PWD" "$dir/$2" || return $?
			echo "Success: Set '$2' pointing to $PWD"
		# otherwise check if it already exists
		elif [[ -L "$dir/$2" ]]; then
			echo "Error: Target '$2' already exists." >&2
			return 2
		# otherwise add the symlink
		else
			ln -s "$PWD" "$dir/$2" || return $?
			echo "Success: Added '$2' pointing to $PWD"
		fi
	;;

	# remove an existing target
	'rm' | 'remove')
		# is it a subdir or file of the actual target?
		if [[ "$2" == *\/* || ! -L "$dir/$2" ]]; then
			echo "Error: '$2' is not a target that can be removed." >&2
			return 2
		fi
		rm "$dir/$2" || return $?
		echo "Success: Removed target '$2'"
	;;

	# list all of the targets
	'ls' | 'list')
		local file
		# iterate on the contents of the dir
		for file in "$dir/"*; do
			# is it a symlink to a directory?
			[[ -L "$file" && -d "$file" ]] || continue
			echo "$(basename "$file") -> $(readlink "$file")"
		done
	;;

	# show all of the targets pointing to the cwd
	'show')
		local file
		# iterate on the contents of the dir
		for file in "$dir/"*; do
			# is it a symlink to a directory?
			[[ -L "$file" && -d "$file" ]] || continue
			if [[ "$PWD" -ef "$(readlink "$file")" ]]; then
				echo "$(basename "$file")"
			fi
		done
	;;

	# everything else
	*)
		local target
		# resolve the target
		case "$command" in
			# explicit commands / non-command '--'
			'go' | 'get' | '--')
				if [[ -z "$2" ]]; then
					echo "Error: No target specified." >&2
					return 2
				fi
				target="$2"
			;;

			# implicit command
			*)
				# if there is a second arg, then the command is not valid
				if [[ -n "$2" ]]; then
					echo "Error: Unknown command '$command'" >&2
					return 2
				fi
				target="$1"
			;;
		esac
		# does the target exist?
		if [[ ! -d "$dir/$target" ]]; then
			echo "Error: '$target' is not a valid target." >&2
			return 2
		fi
		# we are going to the target
		if [[ "$command" == 'go' ]] || [[ "$command" != 'get' && -t 1 ]]; then
			# go to the physical (-P) location that the symlink points to
			cd -P "$dir/$target"
		else
			# just printing the target
			echo "$(cd -P "$dir/$target" && pwd)"
		fi
	;;
esac

} # end cdc()
