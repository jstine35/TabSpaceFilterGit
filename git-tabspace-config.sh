#!/bin/bash

# local config feature is provided by this script but is not really recommended.
# It makes more sense (usually) to just use a global config and then manage local
# configs using only the .gitattributes or .git/info/attributes to control filter usage.

# TODO: Local `disable` feature should operate differently from local `uninstall` feature:
#    disable          - clean and smudge filters should be set to `cat` to override global settings.
#    remove/uninstall - clean and smudge filters should be unset, so that global settings are used.
#  In both cases, the actual filter settings for the local repo should be shown to the user.

FILTER_MODE=help
SHOW_HELP=0
GLOBAL_INSTALL=1
REMOVE_INSTALL=0
EDIT_AS_TABS=0
SHOW_INVALID_OPT=0
ts=4

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--tabsize)
    ts="$2"
    shift 2 # past argument + value
    ;;
    --filter-input|--edit-as-spaces)
    EDIT_AS_TABS="0"
	SHOW_HELP=0
    shift
    ;;
    --filter-all|--edit-as-tabs)
    EDIT_AS_TABS="1"
	SHOW_HELP=0
    shift
    ;;
    -g|--global)
    GLOBAL_INSTALL="1"
    shift
    ;;
    -l|--local)
    GLOBAL_INSTALL="0"
    shift
    ;;
    --uninstall|--disable|--edit-as-is|--filter-none)
    REMOVE_INSTALL=1
	SHOW_HELP=0
    shift
    ;;
    --help)
    SHOW_HELP=1
    shift
    ;;
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
    echo "Installs clean/smudge filter family 'tabspace' configured to a specified"
    echo "tab size and local whitespace mode."
    echo
	echo " --global  |-g       Applies changes to the global .gitconfig (default)"
	echo " --local   |-l       Applies changes to the local repository (not recommended)"
	echo " --tabsize |-t       Sets tabsize for file types without a fixed tabsize attribute (default: 4)"
	echo " --edit-as-spaces    Workspace text files will have all whitespace expanded as spaces (default)"
	echo " --edit-as-tabs      Workspace text files will have _leading line_ tabulators only"
	echo " --edit-as-is        Workspace text files will reflect exact whitespace in the index, but"
	echo "                     will _still_ be normalized as spaces when updating the index"
	echo " --disable           No whitespace normalization is performed. Effective on local repositories"
	echo "                     even when a global setting is in effect"
	echo " --uninstall         Removes  TabSpace filter configurations. If done locally then TabSpace behavior"
	echo "                     will revert back to whatever is configred globally"
	echo
	echo "Usage Examples:"
    echo "  $ $me [repository_path]"
	echo
	echo "To edit locally as tabs instead of spaces (not recommended due to caveats):"
	echo "  $ $me --edit-as-tabs [--local] [repository_path]"
	echo
	echo "To disable TabSpace filtering for a specific repository:"
    echo "  $ $me --disable --local [repository_path]"
    echo
    echo '  `repository_path` is optional.  If not specified, the GIT repository associated'
    echo '  with the CWD is used.  The repository_path is unused when --global is specified.'
    echo
    
    exit 1
fi

if [[ "$SHOW_INVALID_OPT" -eq "1" ]]; then
	>&2 echo "Try --help for available options."
	exit 1
fi

if [[ "$GLOBAL_INSTALL" -eq "0" ]]; then
    rootpath=${1:-$(pwd)}
    if [[ "$rootpath" == */.git/* || "$rootpath" == */.git ]]; then
        while [[ "$rootpath" == */.git/* || "$rootpath" == */.git ]]; do
            rootpath=$(dirname "$rootpath"); 
        done
        cd "$rootpath"
    fi

    gitpath=$(git rev-parse --show-toplevel)

    # rev-parse returns a malformed filename on Windows OS, which contains both a drive:colon
    # specifier and forward slashes, eg c:/some/path -- this confuses msys into not auto-correcting
    # the path to the expected bash format of /c/some/path.  So we must do so manually via cygpath,
    # elsewise some of our later commands like grep might fail to find the file...

    if which cygpath >& /dev/null; then
        gitpath=$(cygpath "$gitpath")
    fi

    if [[ -z "$gitpath" ]]; then
        >&2 echo "ERROR: CWD is not a valid or recognized GIT directory."
        exit 1
    fi

    cd "$gitpath"

    scopestr="--local"
	echo "Applying local changes to clone @ $gitpath"
else
    scopestr="--global"
	echo "Applying changes globally."
fi

getSmudgeAction() {
	if [[ "$1" -eq "1" ]]; then
		echo "unexpand --tabs=$2 --first-only"
	else
		echo "cat"
	fi
}

if   [[ "$REMOVE_INSTALL" -eq "0" ]]; then
    printf "Registering filters with tabsize=$ts..."
	
	smudgeAction=$(getSmudgeAction "$EDIT_AS_TABS" $ts)
	
    git config "$scopestr"  filter.tabspace.clean     "expand   --tabs=$ts"             || exit -1
    git config "$scopestr"  filter.tabspace.smudge    "$smudgeAction"                   || exit -1
    git config "$scopestr"  filter.spaceonly.clean    "expand   --tabs=$ts"             || exit -1
    git config "$scopestr"  filter.spaceonly.smudge   "cat"                             || exit -1

    for ats in 2 3 4 8; do
        printf "."
		smudgeAction=$(getSmudgeAction "$EDIT_AS_TABS" $ats)
        git config "$scopestr"  filter.tabspace$ats.clean    "expand   --tabs=$ats"     || exit -1
        git config "$scopestr"  filter.tabspace$ats.smudge   "$smudgeAction"            || exit -1
        git config "$scopestr"  filter.spaceony$ats.clean    "expand   --tabs=$ats"     || exit -1
        git config "$scopestr"  filter.spaceonly$ats.smudge  "cat"                      || exit -1
    done
    printf "DONE!\n"
    echo
    echo "TabSpace filtering has been installed.  Filtering will be applied to files according"
    echo "to gitattribute specifications, which are typically set up on a per-project basis."
    echo
    echo "Use git-tabspaceattrib.sh to get a list of current recommended file extension filters"
	echo "for use in .gitattributes, or to install attributes into .git dir (untracked)."
	echo
    echo "For best results, use git-tabspace-normalize.sh to normalize whitespace before"
    echo "checking in a modified .gitattributes file."
    echo
else
    printf "Unregistering all TabSpace filters.."
	
	# git config returns code "5" on --unset if the setting didn't exist to be removed.
	# We don't want to quit/abort on such an error, so don't catch errors here.

    git config "$scopestr"  --unset filter.tabspace.clean
    git config "$scopestr"  --unset filter.tabspace.smudge
    git config "$scopestr"  --unset filter.spaceonly.clean
    git config "$scopestr"  --unset filter.spaceonly.smudge

    for ats in 2 3 4 8; do
        printf "."
        git config "$scopestr" --unset filter.tabspace$ats.clean
        git config "$scopestr" --unset filter.tabspace$ats.smudge  
        git config "$scopestr" --unset filter.spaceonly$ats.clean
        git config "$scopestr" --unset filter.spaceonly$ats.smudge  
    done
    printf "DONE!\n"
    
	if [[ "$GLOBAL_INSTALL" -eq "0" ]]; then
		echo
		echo "Local TabSpace filtering has been disabled. TabSpace filter specifications in existing"
		echo ".gitattributes will be ignored and executing git-tabspace-normalize.sh will have no"
		echo "effect on tabs/spaces whitespace. Normalization of newlines may still occur."
		echo
	else
		echo
		echo "Global TabSpace filtering has been disabled. Be weary that local TabSpace filtering"
		echo "configurations may still be bound to individual projects, if you have used this tool"
		echo "previously to install local filter settings."
		echo
	fi
fi

exit 0