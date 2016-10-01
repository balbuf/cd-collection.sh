#!/bin/sh

function cdc() {

# basic usage instructions
if [[ -z "$@" || "$1" == 'help' ]]; then
	cat <<-'DOG'
		usage: cdc [--] <alias>[/<relative-path>]
		       cdc <command> [<args>]

		COMMANDS

		   add    Add a new alias without overwriting an existing alias
		   get    Get the path of a given alias
		   go     Go to the path of the given alias
		   help   Display this message
		   ls     List all existing aliases
		   set    Add or overwrite an existing alias
		   show   Show any aliases pointing to the current directory
		   rm     Remove an existing alias

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
			echo 'Error: Alias name cannot contain a forward slash.' >&2
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
			echo "Error: Alias '$2' already exists." >&2
			return 2
		# otherwise add the symlink
		else
			ln -s "$PWD" "$dir/$2" || return $?
			echo "Success: Added '$2' pointing to $PWD"
		fi
	;;

	# remove an existing alias
	'rm' | 'remove')
		# is it a subdir or file of the actual alias?
		if [[ "$2" == *\/* || ! -L "$dir/$2" ]]; then
			echo "Error: '$2' is not an alias that can be removed." >&2
			return 2
		fi
		rm "$dir/$2" || return $?
		echo "Success: Removed alias '$2'"
	;;

	# list all of the aliases
	'ls' | 'list')
		local file
		# iterate on the contents of the dir
		for file in "$dir/"*; do
			# is it a symlink to a directory?
			[[ -L "$file" && -d "$file" ]] || continue
			echo "$(basename "$file") -> $(readlink "$file")"
		done
	;;

	# show all of the aliases pointing to the cwd
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
		local alias
		# resolve the alias
		case "$command" in
			# explicit commands / non-command '--'
			'go' | 'get' | '--')
				if [[ -z "$2" ]]; then
					echo "Error: No alias specified." >&2
					return 2
				fi
				alias="$2"
			;;

			# implicit command
			*)
				# if there is a second arg, then the command is not valid
				if [[ -n "$2" ]]; then
					echo "Error: Unknown command '$command'" >&2
					return 2
				fi
				alias="$1"
			;;
		esac
		# does the alias exist?
		if [[ ! -d "$dir/$alias" ]]; then
			echo "Error: '$alias' is not a valid alias." >&2
			return 2
		fi
		# we are going to the alias
		if [[ "$command" == 'go' ]] || [[ "$command" != 'get' && -t 1 ]]; then
			# go to the physical (-P) location that the symlink points to
			cd -P "$dir/$alias"
		else
			# just printing the alias
			echo "$(cd -P "$dir/$alias" && pwd)"
		fi
	;;
esac

} # end cdc()
