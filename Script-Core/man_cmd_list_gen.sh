#!/bin/bash
# ------------------------------------------------------------------------------
#	sea's Script Tools: The 3rd Generation
#	Description:	Generates a list of commands available in the scripts
#
	script_version=0.8
#	License:	GPL v3
#	Author:		Simon A. Erat (sea) <erat.simon AT gmail.com>
#	Created:	2012.05.09
#	Changed:	2013.06.08
#	Resources:	http://forums.fedoraforum.org/showthread.php?p=1655027#post1655027
#			http://www.tldp.org/HOWTO/Man-Page/q3.html
# ------------------------------------------------------------------------------
# 
#	Script tools compatibility
#
	if [ ! -f /usr/share/script-tools/st.cfg ]
	then	default_user="YOUR NAME"
		default_email="yourname@domain.url" # OR ::->    your DOT name AT domain DOT url
		APP_PDF=mupdf		# app to review the files
		APP_BROWSER=firefox	# app to review the files
		DONE="[ DONE ]"
		FAIL="[ FAIL ]"
		WORK="[ WORK ]"
		clear ; clear
		shopt -s expand_aliases
		alias sT="echo -e '\n\n\t\t'"
		alias sP="printf '\r'"
		alias sE="echo"
		alias sInst="sudo yum install"	# This is very limited as main audience is redhat based
		ReportStatus() { [ $1 -eq 0 ] && echo "$DONE  $2" ; [ $1 -eq 1 ] && echo "$FAIL  $2" ; [ $1 -eq 3 ] && sP "$WORK  $2" ; return $1 ; }
		ask() { echo;echo;read -n1 -p "$1 (y/n)" answer ; [ [joys] = $answer ] && retvalue=0 || retvalue=1 ; printf "\n";return $retvalue; }
		input() { echo;echo;read -p "$1 " input ; echo "$input" ; }
		press() { read -p "Press [ ENTER ] to continue..." buffer ; }
		sEdit() { for editor in gedit kedit nano vim vi ed;do $editor "$1" && return 0;done;return 1;}
		CheckPath() { [ ! -d "$1" ] && ( mkdir -p "$1" && echo "$DONE Created \"$1\"" || echo "$FAIL Could not create $1" ) || echo "$DONE Path exists" ; }
	else	[ -z $stDir ] && source /usr/share/script-tools/st.cfg
	fi
#
#	Title
#
	sT "sea's CommandList and Manpage generator ($script_version)"
#
#	Variables
#
	SEARCH_STRING="() { #"
	SEARCH_LEN=${#SEARCH_STRING}
	C=0 ; minsize=0
	OUTPUT_CL=""
	INPUT_CL=""
	OUTPUT_MAN=""
	OUTPUT_MAN=""
	INPUT_RM=""
	OUTPUT_RM=""
	TITLE=""
	failed=""
	doPDF=false
	doHTML=false
	unset dash[@] ; dash=("-" "\\" "|"  "/" )
	thisHelp="st dev genman ($script_version)
			\rUsage: genman [args]
			\r\t-h\t\t\tThis Help screen
			\r\t-t TITLE\tDefines which 'project' this manpage is for
			\r\t-ci \$DIR/AS/INPUT\tDefines other source than \$SEA_INCLUDE_DIR
			\r\t-co /PATH/TO/OUTPUTFILE\tDefines other output than \$SEA_DOC_DIR/CommandList
			\r\t-mi /path/as/INPUTDIR\tDefines other inputdir to parse for default.info|help and \$found_file -h
			\r\t-mo \$DIR/to/OUTPUTDIR\tMust be after MAN_INPUTDIR, defines where the generated manpages are saved.
			\r\t-ri /read/me/src\tWhere is the header-template?
			\r\t-ro /readme/out/file\tWhere to save the generated helpfile.
			\r\t-export pdf|html\tExports each created manpage as given target. Default is no export.
			\r\t\t\t\tTo export as pdf & html, you need to pass: -export pdf -export html
			\r\t-bs NUM \t\tWhere NUM is the minimum byte-size that a generated manpage must have.
			
			\r\tNOTE:
			\r\tFor the man pages, my 'favorite' ones are those named after folders.
			\r\tThese contain default.info|help|seealso|files 'default.\$foldername -h' in this order,
			\r\tand are then filled each found \$(sh \$file -h).
			
			\r\tFor the commandlist, your function definitions 'should' look like this:
			\r\t\tfunction_name() { # ARGUMENTS
			\r\t\t# COMMENTLINE 1
			\r\t\t# COMMENTLINE 2
			"
	args=(${@})
	for arg in "${args[@]}"
	do	D=$[ $C + 1 ]
		case $arg in
		"-export")
			exptar="${args[$D]}"
			[ "" = "$(echo $exptar|tr -d [:space:])" ] && \
				ReportStatus 1 "Usage: nas -export pdf -export html" && \
				exit 1
			[ $exptar = pdf ] && doPDF=true
			[ $exptar = html ] && doHTML=true
			unset -v args[$C] args[$D]
			;;
		"-t")	TITLE=${args[$D]}
			unset	args[$C] args[$D]	
			;;
		"-co")	OUTPUT_CL="${args[ $D ]}"
			unset	args[$C] args[$D]
			;;
		"-ci")	INPUT_CL="${args[ $D ]}"
			unset	args[$C] args[ $D ]
			;;
		"-mo")	OUTPUT_MAN="${args[ $D ]}"
			unset	args[$C] args[ $D ]
			;;
		"-mi")	INPUT_MAN="${args[ $D ]}"
			unset	args[$C] args[ $D ]
			;;
		"-ri")	INPUT_RM="${args[ $D ]}"
			unset	args[$C] args[ $D ]
			;;
		"-ro")	OUTPUT_RM="${args[ $D ]}"
			unset	args[$C] args[ $D ]
			;;
		"-bs")	minsize=${args[$D]}
			unset	args[$C] args[$D]	
			;;
		 "-h"| "-help")	
		 	echo -e "$thisHelp"
			exit 99 ;;
		"st"| "gencmd")
			unset args[$C] ;;
		esac
		((C++))
	done
	[ $minsize -eq 0 ] && minsize=79	# min byte size per manpage
	[ "" = "$(echo $SEA_DOC_DIR)" ] && SEA_DOC_DIR=$HOME
	[ "" = "$(echo $OUTPUT_CL)" ] && OUTPUT_CL="$SEA_DOC_DIR/CommandList"
	[ "" = "$(echo $INPUT_CL)" ] && INPUT_CL="$SEA_INCLUDE_DIR"
	[ "" = "$(echo $INPUT_MAN)" ] && INPUT_MAN="$SEA_CLI_DIR"
	[ "" = "$(echo $OUTPUT_MAN)" ] && OUTPUT_MAN="$SEA_DOC_DIR/man"
	[ "" = "$(echo $INPUT_RM)" ] && INPUT_RM="$SEA_TEMPLATES_DIR/README"
	[ "" = "$(echo $OUTPUT_RM)" ] && OUTPUT_RM="$SEA_DOC_DIR/README"
	[ "" = "$(echo $SEA_CLI_DIR$SEA_INCLUDE_DIR|tr -d [:space:])" ] && \
		echo -e "$thisHelp" && exit 99
	[ "" = "$TITLE" ] && TITLE="sea's Script Tools $stVer"
#
#	One Liners
#
	# Get an empty output file
	[ ! -f "$OUTPUT_CL" ] && touch "$OUTPUT_CL"
	[ -z $stVer ] && \
		printf "# This Command list was generated on $(date), using $(basename $0) $script_version" > "$OUTPUT_CL"|| \
		printf "# This Command list was generated on $(date), using Script-Tools $stVer" > "$OUTPUT_CL"
#
#	Subs
#
	ListTheCommands() { # PATH
	# If you use the same layout "functionname() { # [args]\n#CommentLine1\nCommentLine2"
	# you can use it to collect commands available from your own scripts! :)
		srcdir="$1"
		C=0
		for each in $(ls "$srcdir")
		do	sP "Parsing file: $each...." "[ ${dash[$C]} ] $WORK"  #" \[ Animated_Dash $C ] $WORK"
			echo -e "\n$each:"	>> "$OUTPUT_CL"
			tmp=$(cat $srcdir/$each|egrep "$SEARCH_STRING" -A2 )
			echo -e "$tmp" >> "$OUTPUT_CL"
			((C++))
			[ $C -eq 4 ] && C=0
		done
		sed -i s/"--"/""/g "$OUTPUT_CL"
		ReportStatus $? "Parsed functions, output: $OUTPUT_CL"
	}
	getmoduleofscript() { # /path/to/script | st net yt
	# Searches for matching modules of passed script, parsing its absolute path.
	#
		[ -z $1 ] && ReportStatus 1 "Usage: $0 /path/to/script | st net yt" && return 1
		thisfile=$(echo "$1"|sed -e s\\"/"\\" "\\g)
		for part in $thisfile
		do	var="$(ls $SEA_INCLUDE_DIR|grep '$part')"
			[ ! "" = "$(echo $var)" ] && echo "$var" && return 1
		done
		return 1
	}
	MAN_Create() { # [ INDIR ]   [ OUTDIR ] [-bs=NUM]
	# Tries to cat default.help for each new subfolder it finds in /PATH
	# If no argument is supplied, it generates manpages of script-tools
		[ -z $1 ] && \
			indir="$SEA_CLI_DIR" || \
			indir="$1"
		[ -z $2 ] && \
			outdir="$SEA_DOC_DIR/man" || \
			outdir="$2"
		CheckPath "$outdir" && \
			[ ! "" = "$(ls $outdir)" ] && \
			sP "Creating backup of current manpages of $outdir..." "$WORK" && \
			Prj_Tarball "$outdir" && \
			rm -fr "$outdir"/*
		#
		#	Prepare Array's
		#
		st_list_raw=$(find "$indir/"*|grep -v ^^\.|grep -v ^^\.\.|grep -iv old|grep -iv hide|grep -iv todo|grep -iv removed|grep -iv custom|grep -v default)
		st_list=$(for f in "${st_list_raw}"; do [ ! "." = "${f:0:1}" ] && [ ! st = "$f" ] && printf "$f";done)
		amount=$(echo "$st_list"|grep -v ^^\.|wc -l)
		unset fn[@] mods[@] path[@]
		C=0
		#
		#	Display
		#
		sE "Trying to create manpages from:" "$indir"
		#sE "Found $amount entries to parse..." 
		section=""
		I=0
		for file in ${st_list}
		do 	fn[$C]="$(basename $file)"
			path[$C]="$(dirname $file)"
			mods[$C]="$(getmoduleofscript $file)"
			outfile="$outdir/${fn[$C]}.man"	
		#
		#	Generate MAN title
		#
			work_progress="Parsing $C/$amount: ${fn[$C]}"
			sP "$work_progress" "[ ${dash[$I]} ] $WORK"
			[ ! -f "$outfile" ] && touch "$outfile"
			echo -e ".TH ${fn[$C]} 1 \"$(date +'%Y %m %d')\" \"$TITLE\""  >> "$outfile" # \n.nh\n.ad l
		#
		#	Define Content : Folder
		#			
			if [ -d "${path[$C]}/${fn[$C]}" ] 
			then	section="${fn[$C]}" 
				outfile="$(dirname $outfile)/$section.man"
				[ -f "${path[$C]}/${fn[$C]}/default.title" ] && \
					echo -e ".BR\n.SH SECTION: $(cat ${path[$C]}/${fn[$C]}/default.title)\n.BR\n" >> "$outfile" && \
					touch "${path[$C]}/${fn[$C]}/man.done"
				for job in "info" "help" "config" "seealso" "files" "${fn[$C]}"
				do	[ ! -f "${path[$C]}/${fn[$C]}/man.done" ] && \
						out=".BR\n.SH SECTION: $(Capitalize $section)\n.BR\n" >> "$outfile" && \
						touch "${path[$C]}/${fn[$C]}/man.done"
					[ -f "${path[$C]}/${fn[$C]}/default.$job" ] && \
						echo ".SH $(Capitalize $job):" >> "$outfile" && \
						if [ "$job" = "${fn[$C]}" ] ; then out="$(source ${path[$C]}/${fn[$C]}/default.$job -h)" ;else out="$(cat ${path[$C]}/${fn[$C]}/default.$job)";fi && \
						[ ! "" = "$(echo $out)" ] && \
						echo "$out" >> "$outfile" 
				done
				echo -e ".BR\n.BR\n.SH SUBS:\n.BR\n" >> "$outfile" 
			fi
			[ ! "" = "$section" ] && \
				outfile="$(dirname $outfile)/$section.man"
		#	
		#	Define Content : File
		#
			if [ -f "${path[$C]}/${fn[$C]}" ] 
			then	case "${fn[$C]}" in
				default*) 
					echo "" > /dev/zero
					;;
				*.help)
					
					;;
				*)	if [ ! "" = "$(grep 'h\\t' ${path[$C]}/${fn[$C]})" ]
					then	hlp=$(source ${path[$C]}/${fn[$C]} -h)
						first=$(echo "$hlp"| grep -v '#'|grep [0-9]\.[0-9])
						other=$(echo "$hlp"| grep -v '#'|grep -v [0-9]\.[0-9])
						if [ "" = "$first" ] 
						then	echo -e "* ${fn[$C]} is missing help"  >> "$outfile" 
						else	echo ".SH Name:"  >> "$outfile"
							[ -f "$outdir/${fn[$C]}.name" ] && \
								echo "$first - $(cat $outdir/${fn[$C]}.name)"  >> "$outfile" || \
								echo "$first"  >> "$outfile"
							
							
							[ -f "${path[$C]}/${fn[$C]}.help" ] && \
								echo ".SH Description:"  >> "$outfile" && \
								echo "$(cat ${path[$C]}/${fn[$C]}.help)"  >> "$outfile"
							echo ".SH Synopsis:" >> "$outfile"
							echo -e ".PP\n$other\n.PP"  >> "$outfile"
						fi
					fi
					;;
				esac
			fi
		#
		#	Loop counter & Formatting hotfix
			((C++))
			((I++))
			[ $I -eq 4 ] && I=0
			sed s/"\t\t-"/"\n-"/g -i "$outfile"
			sed s/"\t"/"    "/g -i "$outfile"	
		done
		[ -f "$outdir/man.done.man" ] && rm "$outdir/man.done.man"
		ReportStatus 0 "Parsed $C entries and created $(ls $outdir/*.man|grep -v ^^\.|wc -l) files."
		#
		# 	Removing unusable Manpages
		#
			i=0
			C=0
			for toRemove in $(ls "$outdir")
			do	sP "Removing manpages ($i) that are smaller than $minsize bytes" "[ ${dash[$C]} ] $WORK" && \
				num=$(ls -l "$outdir/$toRemove"|awk '{print $5}')
				[ $num -le $minsize ] && \
					rm -fr "$outdir/$toRemove" && ((i++)) 
				((C++))
				[ $C -eq 4 ] && C=0
			done
			ReportStatus $? "Removed $i man pages that were smaller than $minsize bytes." # "$DONE"
		#
		#	Generate MAN footer
		#
			C=0;i=0
			for outfile in $(ls "$outdir")
			do	sP "Appending footer to manpages..." "[ ${dash[$I]} ] $WORK"
				echo ".SH Manpage created by:"  >> "$outfile"
				echo  "$default_user, using man_cmd_list_gen.sh $script_version" >> "$outfile"
				echo ".SH Contact:" >> "$outfile"
				echo "$(echo $default_email|sed s/' AT '/'@'/g|sed s/' DOT '/'\.'/g)" >> "$outfile"
				((C++))
				((I++))
				[ $I -eq 4 ] && I=0
			done
			sE "Appended footer to $(ls $outdir/*.man|wc -l) manpages." "$DONE"
		#
		#	Handle exports
		#
			failed=""
			for JOB in PDF HTML
			do	case $JOB in
				PDF)	if [ true = $doPDF ]
					then	sT "Creating PDF's"
						td="$(dirname $outdir)/pdf"
						export OUTPUT_PDF="$td"
						CheckPath "$td"
						C=0
						for outfile in $(ls "$outdir")
						do	tf="${outfile:0:(-4)}.pdf"
							sP "Generating: $tf" "[ ${dash[$I]} ] $WORK"
							man -Tps "$outdir/$outfile" | ps2pdf - "$td/$tf"
							((C++))
							((I++))
							[ $I -eq 4 ] && I=0
						done
						sE "Created $C pdf files." "$DONE"
					fi
					;;
				HTML)	if [ true = $doHTML ]
					then	sT "Creating HTML's"
						td="$(dirname $outdir)/html"
						export OUTPUT_HTML="$td"
						CheckPath "$td"
						C=0 ; I=0
						for outfile in $(ls "$outdir")
						do	tf="${outfile:0:(-4)}.html"
							sP "Generating: $tf" "[ ${dash[$I]} ] $WORK"
							man -Thtml "$outdir/$outfile" > "$td/$tf"
							((C++))
							((I++))
							[ $I -eq 4 ] && I=0
						done
						sE "Created $C html files." "$DONE"
					fi
					;;
				esac
			done
			
			rm $(find $indir/ -name man.done) > /dev/zero
			return 0
	}
	ask_gencmd_review() { #
	#
	#
		ask "Show the Command List now?" && cat "$OUTPUT_CL" | more
		ask "Edit the Command List?" && sEdit "$OUTPUT_CL"
		ask "Review manpages?" && \
			select task in Back $(ls "$OUTPUT_MAN/" )
			do	[ $task = Back ] && break
				man "$OUTPUT_MAN/$task"
			done
		[ true = $doHTML ] && \
			ask "Review html pages?" && \
			select task in Back $(ls "$OUTPUT_HTML/" )
			do	[ $task = Back ] && break
				$APP_BROWSER "$OUTPUT_HTML/$task"
			done
		[ true = $doPDF ] && \
			ask "Review pdf files?" && \
			select task in Back $(ls "$OUTPUT_PDF/" )
			do	[ $task = Back ] && break
				$APP_PDF "$OUTPUT_PDF/$task"
			done
	}
	ReadMe_Create() { # "$INPUT_RM" "$OUTPUT_RM"
	#
	#
		INPUT_RM="$1"
		OUTPUT_RM="$2"
		cat "$INPUT_RM" > "$OUTPUT_RM"
		sE "TODO" "$TODO"
	}
#
#	Display
#
	for task in CommandList ManPages ReadMe
	do	sT "Creating $task"
		case $task in
		"CommandList")	sE "Generating commands $OUTPUT_CL from:" "$INPUT_CL"
				ListTheCommands "$INPUT_CL"
				;;
		"ManPages")	MAN_Create "$INPUT_MAN" "$OUTPUT_MAN"
				;;
		"ReadMe") 	ReadMe_Create "$INPUT_RM" "$OUTPUT_RM"	
				;;
		esac
	done
	sT " Review results"
	ask_gencmd_review
	return $?
