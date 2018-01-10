#!/bin/bash
#
# this is a "build/merge test" version of git-normalized-indexed-files.sh
# It does not retain the resulting commit, instead rolling back the git state and
# returning an error code to represent success or failure.
#


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
    exit 1
fi

# see git-normalized-indexed-files.sh for full explanation of this process.
# in short: git optimizes the working tree in clever ways, and the only way to avoid
# inconsistent behavior is to stage everything as commits and thus force GIT to execute
# smudge/clean filters on the internal files, thus avoiding working tree filesystem
# optimization behaviors.

restore_ref=$(git rev-parse HEAD)

echo "Normalizing all indexed files (may take a while)..."
git reset --hard
list=($(git ls-files))
total=${!list[@]}
echo "  > removing all files from index"
git rm --cached -r . > /dev/null
git commit -F - <<< "normalized whitespace" > /dev/null 
echo "  > re-adding files to index"
echo "${list[@]}" | xargs -P1 -n16 git add -- 
echo "  > Amending commit 'normalize whitespace'"
if ! git commit -C HEAD --amend > /dev/null 2>&1; then 
	echo "  > normalization check passed!"
    printf "Rolling back staged normalization commit... "
    git checkout $restore_ref
    echo "all done!"
else
	>&2 echo "  > 'normalized whitespace' commit failed."
	>&2 echo "  > The following files have inconsistent newlines or whitespace:"
	git show --format=oneline --name-only HEAD | tail -n +1 >2
    git checkout $restore_ref > /dev/null 2>&1
    >&2 echo "ERROR: Inconsistent newlines or whitespace detected!"
    exit 2
fi

exit 0