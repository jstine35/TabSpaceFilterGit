#!/bin/bash

CLIBOARD=0
PRINT_STDOUT=0

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
	-p|--print)
	PRINT_STDOUT=1
    shift
    ;;
    --clip|--clipboard)
    CLIBOARD=1
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

asset_dir=$(dirname "$0")

exit_time=0
if [[ "$PRINT_STDOUT" -eq "1" ]]; then
	cat "$asset_dir/gitattributes.sample"
	exit_time=1
fi

if [[ "$CLIBOARD" -eq "1" ]]; then
	cat "$asset_dir/gitattributes.sample" > /dev/clipboard
	exit_time=1
fi

[ "$exit_time" -eq "1" ] && exit 0

rootpath=${1:-$(pwd)}
if [[ "$rootpath" == */.git/* || "$rootpath" == */.git ]]; then
    while [[ "$rootpath" == */.git/* || "$rootpath" == */.git ]]; do
        rootpath=$(dirname "$rootpath"); 
    done
    cd "$rootpath"
fi

gitpath=$(git rev-parse --show-toplevel)

if where cygpath > /dev/null 2>&1; then
    gitpath=$(cygpath "$gitpath")
fi

if [[ -z "$gitpath" ]]; then
    >&2 echo "ERROR: CWD is not a valid or recognized GIT directory."
    exit 5
fi

attribdest="$gitpath/.git/info/attributes"

if [[ -s "$gitpath/.git/info/attributes" ]]; then
	if cmp -s "$asset_dir/gitattributes.sample" "$attribdest"; then
		# files are the same, nothing to do!
		exit 0
	else
		>&2 echo "$attribdest : already exists and has unknown contents."
		>&2 echo "Please update the file manually. Load the file into a test editor"
		>&2 echo "and then run this tool with --clip to copy the tabspace attributes"
		>&2 echo "filters into the clipboard."
		exit 1
	fi
fi

cp "$asset_dir/gitattributes.sample" ".git/info/attributes"
