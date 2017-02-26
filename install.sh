#!/bin/sh

# wrap in subshell to ensure entire file is downloaded to be executed
(

# set default directory to store cd targets and cdc source itself
CDC_DIR="${CDC_DIR:-$HOME/.cd_collection}"
# default location to download source file to
CDC_LOCATION="${CDC_LOCATION:-$CDC_DIR/cd_collection.sh}"
# base URL for GitHub API
GH_API="https://api.github.com"
# cdc repo name
REPO_NAME="balbuf/cd-collection.sh"
# comment inside of initialization file to identify our line
LINE_MARKER="# Added by cdc"

# get the value associated with the provided json field name from the piped in json
function get_field() {
	awk -F'" ?: ?"' '/"'"$1"'"/ { gsub(/",?$/, "", $2); print $2}'
}

# determine what shell initialization file to use
if [ -z "$INIT_FILE" ]; then
	case "$(basename -- "$SHELL")" in
		bash)
			# on OSX use ~/.bash_profile instead of .bashrc
			if [ "$(uname)" = Darwin ]; then
				INIT_FILE=~/.bash_profile
			else
				INIT_FILE=~/.bashrc
			fi
		;;

		ksh)
			INIT_FILE=~/.kshrc
		;;

		zsh)
			INIT_FILE=~/.zshrc
		;;
	esac
fi

# do we have an initialization file?
if [ -n "$INIT_FILE" ]; then
	# does the file exist?
	if [ ! -f "$INIT_FILE" ]; then
		# proceed but don't write to any file
		INIT_FILE=""
	else
		# have we already added our line to the init file? if so, use the existing source file path
		EXISTING_CDC="$(awk '/'"$LINE_MARKER"'/ {print $2}' "$INIT_FILE")"
		if [ -n "$EXISTING_CDC" ]; then
			CDC_LOCATION="$EXISTING_CDC"
		# otherwise can we write to the file?
		elif [ ! -w "$INIT_FILE" ]; then
			# proceed but don't write to any file
			INIT_FILE=""
		fi
	fi
fi

# specific release tag can be passed as the first arg
if [ -n "$1" ]; then
	RELEASE_TAG="$1"
else
	# otherwise get the tag for the latest release
	RELEASE_TAG="$(curl -sL "{$GH_API}/repos/{$REPO_NAME}/releases/latest" | get_field tag_name)"
fi

# get the download URL for the cdc source
FILE_URL="$(curl -sL "{$GH_API}/repos/{$REPO_NAME}/contents/cd-collection.sh?ref=$RELEASE_TAG" | get_field download_url)"

# do we have a source file to download?
if [ -z "$FILE_URL" ]; then
	echo 'Error resolving source file for the requested release'
	exit 1
fi

# create directory for source file
if ! mkdir -p "$(basename "$CDC_LOCATION")"; then
	echo 'Could not create parent directory for source file'
	exit 1
# download cdc source file
elif ! curl -sLo "$CDC_LOCATION" "$FILE_URL"; then
	echo 'Problem downloading source file'
	exit 1
fi

# do we have an init file to modify?
if [ -z "$INIT_FILE" ]; then
	cat <<-DOG
		Success: cdc version $RELEASE_TAG has been successfully downloaded!

		We were unable to modify your shell initialization file - you'll need to manually add the following line:

		    . $CDC_LOCATION

		To use this cdc version in any shell windows or tabs that are currently open,
		you must manually source your shell initialization file.
	DOG
else
	# do we need to add our line?
	if [ -z "$EXISTING_CDC" ]; then
		# back up the original init file
		cp "$INIT_FILE"
		# add our line to the init file
		echo ". $CDC_LOCATION $LINE_MARKER (see https://github.com/balbuf/cd-collection.sh)" >> "$INIT_FILE"
	fi

	# success!
	cat <<-DOG
		Success: cdc version $RELEASE_TAG has been successfully installed!

		To use this cdc version in any shell windows or tabs that are currently open,
		you must manually source your shell initialization file, like so:

		    source $INIT_FILE
	DOG
fi

)
