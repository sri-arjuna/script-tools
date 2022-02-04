#/usr/bin/env bash
# User config / preparation
	if [[ -z "$GIT_PROVIDER" ]]
	then
		printe "$GIT_MSG_PROVIDER"
		GIT_PROVIDER=$(pick $(<"$LIST_DIR/git_providers"))
		git.save GIT_PROVIDER "$GIT_PROVIDER"
	fi
	if [[ -z "${GIT_PROVIDER}_LOGIN" ]]
	then
		GIT_LOGIN=$(ask "$GIT_MSG_YOUR_LOGIN ($GIT_PROVIDER)")
		git.save ${GIT_PROVIDER}_LOGIN "$GIT_LOGIN"
	fi
# Output
	if [[ ! -f "$GIT_CFG_HOME" ]]
	then	status 111 "$SWARM_MSG_PHRASE_FILE_EXISTS" "$GIT_CFG_HOME"
		printfile "$GIT_CFG_HOME"
		# Skip change home gitconfig changes
		if ${do_git_cfg_change:-true} && ! yesno "$GIT_MSG_CHANGE_HOME_CONFIG"
		then	do_git_cfg_change=false
			git.log "$GIT_MSG_HOME_CONFIG_SKIP"
			git.save do_git_cfg_change false
		fi
	fi
# Input
	if $do_git_cfg_change
	then
		. ./home
		git.log "$GIT_MSG_HOME_CONFIG_CREATED"
		git.save "do_git_cfg_change" "false"
	fi
