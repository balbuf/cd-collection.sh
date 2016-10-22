#!/bin/sh

# set default directory to store cd targets
CD_COLLECTION="${CD_COLLECTION:-$HOME/.cdcollection}"

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
	# return non-zero exit code if help was not explicitly invoked
	return $([[ "$1" == 'help' ]]; echo $?)
fi

local command="$1"

# what command are we running?
case "$command" in
	# get the version number
	--version)
		echo 'cd Collection version 0.34'
	;;

	# create a new bookmark or overwrite existing
	set | add)
		# check the name format
		if [[ "$2" == *\/* ]]; then
			echo 'Error: Alias name cannot contain a forward slash.' >&2
			return 2
		fi

		# make sure dir exists
		mkdir -p "$CD_COLLECTION"

		# attempt to add or overwrite the symlink
		if [[ "$command" == 'set' ]]; then
			ln -sfn "$PWD" "$CD_COLLECTION/$2" || return $?
			echo "Success: Set '$2' pointing to $PWD"
		# otherwise check if it already exists
		elif [[ -L "$CD_COLLECTION/$2" ]]; then
			echo "Error: Alias '$2' already exists." >&2
			return 2
		# otherwise add the symlink
		else
			ln -s "$PWD" "$CD_COLLECTION/$2" || return $?
			echo "Success: Added '$2' pointing to $PWD"
		fi
	;;

	# remove an existing alias
	rm | remove)
		# is it a subdir or file of the actual alias?
		if [[ "$2" == *\/* || ! -L "$CD_COLLECTION/$2" ]]; then
			echo "Error: '$2' is not an alias that can be removed." >&2
			return 2
		fi
		rm "$CD_COLLECTION/$2" || return $?
		echo "Success: Removed alias '$2'"
	;;

	# list all of the aliases
	ls | list)
		local file
		# iterate on the contents of the dir
		for file in "$CD_COLLECTION/"*; do
			# is it a symlink to a directory?
			[[ -L "$file" && -d "$file" ]] || continue
			echo "$(basename "$file") -> $(readlink "$file")"
		done
	;;

	# show all of the aliases pointing to the cwd
	show)
		local file
		# iterate on the contents of the dir
		for file in "$CD_COLLECTION/"*; do
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
			go | get | --)
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
		if [[ ! -d "$CD_COLLECTION/$alias" ]]; then
			echo "Error: '$alias' is not a valid alias." >&2
			return 2
		fi
		# we are going to the alias
		if [[ "$command" == 'go' ]] || [[ "$command" != 'get' && -t 1 ]]; then
			# go to the physical (-P) location that the symlink points to
			cd -P "$CD_COLLECTION/$alias"
		else
			# just printing the alias
			echo "$(cd -P "$CD_COLLECTION/$alias" && pwd)"
		fi
	;;
esac

} # end cdc()

# tab completion
function _cdc() {

	# bail for case where we wouldn't have completions
	if [[ $COMP_CWORD > 2 ]] || [[ $COMP_CWORD == 2 && "$3" == cdc ]]; then
		return 1
	fi

	# $3 is the word preceding the current tab completion word; $2 is the current word
	case "$3" in

		cdc | get | go | --)
			# get directory completions relative to the cd collection dir and suffic with slash
			COMPREPLY=( $(cd "$CD_COLLECTION"; compgen -d -S / -- "$2") )
		;;

		rm | remove | set)
			# only return actual symlinks in our directory
			COMPREPLY=( $(compgen -W "$(find "$CD_COLLECTION" -maxdepth 1 -type l -print0 | xargs -0 basename)" -- "$2" ) )
		;;

	esac

}
# use our custom complete function - don't add a space after completion
complete -o nospace -o filenames -F _cdc cdc
