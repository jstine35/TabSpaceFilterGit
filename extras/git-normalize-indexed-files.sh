#!/bin/bash
#
# git has some very clever filesystem optimization tricks which can lead to seemingly unpredictable results
# when trying to get it to normalize all the files according to set filters.  Files which become normalized
# (tabs converted to spaces) may, inexplicably at any time, revert back to the tabulated files stored in the
# repo.  This happens because git doesn't really see the filtered files as having meaningful changes and thusly
# may 'optimize' them back into hardlinks at any time it sees fit.  The conditions in which git uses hardlink
# optimization also depends on the age of the repo and how many workspace files in the local clone are stored
# in .pack files.  In other words, behavior is _very_ unpredictable.
#
#  * git reset --hard isn't enough.
#  * removing all tracked files and doing `git checkout -- .` isn't enough either, and tends only to normalize
#    files that aren't .pack'd
# 
# The only way to do it _reliably_ is to transform the whole process of removing and re-adding files into a
# single internal git operation that literally takes the whole _working copy_ out of the equation.  To do that
# we must stage modified files as a commit, and then squash (amend) the unmodified versions.  Only then will
# the git backend smudge/clean filters do their job with impunity.
#
# Notes:
#  * this method also avoids edge case interference such as tortoisegit keeping a lock on a file and
#    preventing us from removing it.
#


# Dev Note:  `git ls-files` works from the CWD, so use `git rev-parse --show-toplevel` to get the
# root of the repo.

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

echo "Normalizing indexed files (may take a while)..."
git reset --hard
list=($(git ls-files))
echo "  > removing all files from index"
git rm --cached -r . > /dev/null
git commit -F - <<< "normalized whitespace" > /dev/null 
echo "  > re-adding files to index"
echo "${list[@]}" | xargs -P1 -n16 git add -- 
echo "  > Amending commit 'normalize whitespace'"
if ! git commit -C HEAD --amend > /dev/null 2>&1; then 
    echo "  > good news: no whitespace normalization was needed!"
    git reset HEAD^
else
    echo "  > 'normalized whitespace' commit has been created as follows:"
    git show --format=oneline --name-only HEAD^
fi
