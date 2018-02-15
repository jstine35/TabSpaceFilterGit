#!/bin/bash
#
# TODO - WIP!  Finish this!

#	echo " --status            Shows current TabSpace status for specified global or local scope"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in

	--*)   # invalid option, report message and quit.
	>&2 echo "Unrecognized switch: $1"
	SHOW_INVALID_OPT=1
	shift
	;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters
me=$(basename "$0")

if [[ "$SHOW_HELP" -eq "1" ]]; then
	exit 1
fi

if [[ "$SHOW_INVALID_OPT" -eq "1" ]]; then
	>&2 echo "Try --help for available options."
	exit 1
fi


has_local=0
has_global=0

if git config --local  filter.tabspace.clean >& /dev/null; then has_local=1;		fi
if git config --global filter.tabspace.clean >& /dev/null; then has_global=1;		fi

if [[ "$has_local" -eq "0"  && "$has_global" -eq "0" ]]; then
	echo "TabSpace is not installed locally or globally."
	exit 1
fi

if [[ "$has_local" -eq "0" ]]; then	
	zone='--global'
	#echo "  > Local TabSpace configuration is unset (global settings effective)"
	if [[ "$has_global" -eq "0" ]]; then	
		# this is technically unreachable since we check both local/global together earlier.
		>&2 echo "ASSERTION FAILURE. The tool has encountered a programmer logic error."
		exit 1
	else
		
	fi
else
	zone='--local'
fi

cleanmsg=$(git config $zone filter.tabspace.clean)
smudgemsg=$(git config $zone filter.tabspace.smudge)

tabsetting=$(egrep -o -- '--tabsize=[0-9]' <<< "$cleanmsg")

if [[ "$cleanmsg" == "cat" ]]; then
	tabspace_mode='--disabled'
elif grep -w "expand" <<< "$cleanmsg"; then
	if grep -w "unexpand" <<< "$smudgemsg"; then
		tabspace_mode='--edit-as-tabs'
	else
		tabspace_mode='--edit-as-spaces'
	fi
else 
	# unrecognized configuration
	echo "TabSpace filters are using some unrecognized custom configuration."
	exit 1
fi

echo "TabSpace configured as: $zone $tabspace_mode $tabsetting"
exit 0
