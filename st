#!/usr/bin/env bash
#
# Script Header
# aka manual changes
#
	script_name="Script-Tools"
	script_version=2:0.1
	export script_name
 #
 # Dynamic Variables
 #
	ME="${0##*/}"
	ME_DIR="${0/$ME}"
	if [[ "$ME_DIR" == "./" ]]
	then	ME_DIR="$PWD"
		# Save one execution of PWD
		DIR_PREVIOUS="$ME_DIR"
	else	DIR_PREVIOUS="$PWD"
	fi
	cd "$ME_DIR"
#
# Prepare SWARM & configuration
#
	source SWARM/runtime
	# Script specific dirs
	LIST_DIR="$ME_DIR/${ME}.data/lists"
	CONF_DIR="$SWARM_USER_DIR_CONF/${script_name,,}"
	$MKDIR "$CONF_DIR"
	LOG_DIR="$SWARM_LOG_DIR/${script_name,,}"
	# Script specific files
	CONF_FILE="$CONF_DIR/$ME.conf"
	LOG_FILE="$LOG_DIR/$ME.log"
	# Prepare possible user language
	this_lang="${LANG/\.*}"
#
# Load language support
#
	for d in en_GB $this_lang
	do	# Check for directory
		if [[ -d "$ME_DIR/$ME.data/lang/$d" ]]
		then 	for f in "$ME_DIR/$ME.data/lang/$d/"*
			do 	# Load files
				source "$f" && $PRINTF "."
			done
		fi
	done
#
# Load project functions
#
	for f in "$ME_DIR/$ME.data/functions"/*
	do
		source "$f"  && $PRINTF "."
	done
#
# Load User Configuration
#
	for f in $(swarm.list.files "$CONF_DIR")
	do
		source "$CONF_DIR/$f"  && $PRINTF "."
	done
#
# Start browsing or executing arguments
#
	tui "$ME_DIR/$ME.data/menu" "${@}"
	ret=$?
#
# Return to previous location
#
	cd "$DIR_PREVIOUS"
	exit $ret
