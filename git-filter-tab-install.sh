#!/bin/bash

FILTER_MODE=help
SHOW_HELP=0
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
    FILTER_MODE="input"
    shift
    ;;
    --filter-all|--edit-as-tabs)
    FILTER_MODE="all"
    shift
    ;;
    --filter-none|--edit-as-is)
    FILTER_MODE="none"
    shift
    ;;
    --help)
    SHOW_HELP=1
    shift
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

me=$(basename "$0")

if [[ "$SHOW_HELP" -eq "1" || "$FILTER_MODE" == "help" ]]; then
    echo "$me - Sets TabSpace Filtering Rules for GIT"
    echo
    echo "To edit locally as tabs and convert to spaces upstream :"
    echo "  $ $me --tabsize=4 --edit-as-tabs {repository_path}"
    echo
    echo "To edit locally as spaces and convert errant tabs to spaces upstream:"
    echo "  $ $me --tabsize=4 --edit-as-spaces {repository_path}"
    echo
    echo "To disable the filter and restore default  behavior:"
    echo "  $ $me --edit-as-is {repository_path}"
    echo
    echo '  `repository_path` is optional.  If not specified, the GIT repository associated'
    echo '  with the CWD is used.'
    echo
    
    exit 1
fi

set -- "${POSITIONAL[@]}" # restore positional parameters

rootpath=${1:-$(pwd)}
if [[ "$rootpath" == */.git/* || "$rootpath" == */.git ]]; then
    while [[ "$rootpath" == */.git/* || "$rootpath" == */.git ]]; do
        rootpath=$(dirname "$rootpath"); 
    done
    cd "$rootpath"
fi

gitpath="$(git rev-parse --show-toplevel)"

if [[ -z "$gitpath" ]]; then
    >&2 echo "ERROR: CWD is not a valid or recognized GIT directory."
    exit 1
fi

echo "Applying changed to clone @ $gitpath"

gitpath="$(readlink -f "$gitpath")"
gitpath="$gitpath/.git"

if [[ "$FILTER_MODE" == "none"  ]]; then
    printf "Disabling filter.autoexpandtabs... "
    git config --local filter.autoexpandtabs.clean  ""                       || exit -1
    git config --local filter.autoexpandtabs.smudge ""                       || exit -1
    printf "DONE!\n"
fi

if [[ "$FILTER_MODE" == "all"   ]]; then
    printf "Registering filter.autoexpandtabs with tabsize=$ts... "
    git config --local filter.autoexpandtabs.clean  "expand --tabs=$ts"      || exit -1
    git config --local filter.autoexpandtabs.smudge "unexpand -a --tabs=$ts" || exit -1
    printf "DONE!\n"
fi

if   [[ "$FILTER_MODE" == "input" ]]; then
    printf "Registering filter.autoexpandtabs with tabsize=$ts... "
    git config --local filter.autoexpandtabs.clean  "expand --tabs=$ts"      || exit -1
    git config --local filter.autoexpandtabs.smudge ""                       || exit -1
    printf "DONE!\n"
fi

attrib_file="$gitpath/info/attributes"

filetypes=(
    "*.py"
    "*.c"
    "*.cpp"
    "*.h"
    "*.hpp"
    "*.inl"
    "*.sh"
    "*.lua"
    "*.bat"
    "*.cmd"
)

# when uninstalling filter, don't bother adding/updating the attributes file.
if [[ "$FILTER_MODE" == "none"  ]]; then
        exit 0
fi

echo "Updating $(readlink -f "$attrib_file")..."

for ft in ${filetypes[@]}; do
    # check if entry for this file type already exists, if so then do not append duplicate.
    # this works nicely to allow a user to comment out lines manually in their attributes file,
    # and this script won't modify or override that preference.
    
    printf "    %-8s   --> " "$ft"
    if grep "$ft"  "$attrib_file" | grep "autoexpandtabs" > /dev/null 2>/dev/null; then
        echo "SKIPPED"
    else
        printf "%-8s   filter=autoexpandtabs\n" "$ft"  >> "$attrib_file"
        echo "ADDED"
    fi
done

echo "(note: any skipped entries already exist in attributes file)"
