#!/bin/bash
# The shebang is for syntax highlighting only
# The file is sourced, so make variables "local"
#
{

	local str=""
#
# Lets make sure the users knows wether we're on an EFI system or not
#
	str=$(efi.check)
	status $? "$str"
#
# Check for efibootmgr, if it is an EFI system
#
	if [[ $? -eq 0 ]]
	then	# It is EFI
		if ! swarm.util.which -q efibootmgr
		then	# Should we install?
			yesno "$SWARM_MSG_WORD_INSTALL efibootmgr?" || return
			swarm.os.install efibootmgr
		fi
	fi
#
# Script should be executed as root
#
	status 111 "$SWARM_MSG_WORD_USER: Root = $isRoot"
}
