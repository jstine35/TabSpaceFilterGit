#!/bin/bash

me=$(basename "$0")
if [[ -z "$1" || "$1" == "--help" ]]; then
	echo "Converts all spaces to tabs in a given directory."
	echo "Modifies *.cpp;*.h;*.inl;*.lua (tabsize=4)"
	echo "	ex:	 $ $me [search_dir]"
	exit -1
fi

find $1 -type f \( -name '*.cpp' -o -name '*.h' -o -name '*.inl' -o -name '*.lua' -o -name "*.sh" -o -name "*.fx" \) -not -path '*imports/*' -exec bash -c 'unexpand -a -t 4 "$0" > /tmp/e && mv  /tmp/e "$0"' {} \;
