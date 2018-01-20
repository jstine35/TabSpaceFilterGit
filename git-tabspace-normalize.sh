#!/bin/bash
#
# Git makes every attempt to be fast and efficient, and this gets in our way when applying new
# smudge/clean filters to a local repository (this includes changes to crlf rules).  This little
# script gets around that by completely removing all tracked files in the repository and then
# executing git checkout, thus ensuring that all files have been smudged as per new rules assignment.
#
# In --dry-run mode this script returns result '1' when the whitespace for the repository
# is not normalized.
#


# Dev Note:  `git ls-files` works from the CWD, so use `git rev-parse --show-toplevel` to get the
# root of the repo.

DRY_RUN=0
FORCE_NORMALIZE=0
SHOW_HELP=0

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--force)
    FORCE_NORMALIZE="1"
    shift
    ;;
    --dry-run)
    DRY_RUN=1
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

if ! git diff-index --quiet HEAD --; then
    if [[ "$FORCE_NORMALIZE" -eq "0" ]]; then
        >&2 echo "ERROR- Local changes detected in the repository."
        >&2 echo "Specify -f to forcibly normalize the repository to the new filter setting."
        exit 1
    fi
fi

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
# Note: this method also avoids edge case interference such as tortoisegit keeping a lock on a file and
#       preventing us from removing it.
#

# what would be nice is if we could somehow lock the whole repo during this series of GIT commands, eg. a
# persistent git.lock file of sorts.  Alas, hacks it is!

if [[ "$DRY_RUN" -eq "1" ]]; then
    echo "Performing whitespace normalization test (--dry-run)"
else
    echo "Normalizing whitespace"
fi

git reset --hard
list=($(git ls-files))
echo "  > removing all files from index"
git rm --cached -r . > /dev/null
git commit -F - <<< "normalized whitespace" > /dev/null
echo "  > re-adding files to index"
echo "${list[@]}" | xargs -P1 -n16 git add -- 
echo "  > Amending commit 'normalize whitespace'"
if ! git commit -C HEAD --amend > /dev/null 2>&1; then 
    echo "  > no whitespace normalization changes detected"
    git reset HEAD^
    exit 0
elif [[ "$DRY_RUN" -eq "1" ]]; then
    >&2 echo "Whitespace normalization check failed for the following files:"
    git show --format=oneline --name-only HEAD^ | tail -n +2 1>&2
    >&2 echo "[/eol]"
    git reset --hard HEAD^ > /dev/null
    exit 1
elif [[ "$DRY_RUN" -eq "0" ]]; then
    echo "  > 'normalized whitespace' commit has been created as follows:"
    git show --format=oneline --name-only HEAD^
    exit 0
fi