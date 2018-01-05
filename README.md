# TabSpaceFilterGit

## What does it do?
It configures a given GIT clone to perform smudge/clean filters on all tab/space characters.  Smudge/Clean filters are the same ones used to implement GIT's LF/CRLF support (via `core.auto_crlf`), and this works the same way: checkout, commit, diff, etc. all work implicitly.  The local user sees everything as either tabs or spaces (depending on user preference), while the upstream repository is stored as spaces.  It's based on proven tech -- LF/CRLF conversion isalrwady used by almost every Git for Windows client in existence.

## What is it and how do I use it?
A mini-installer written in BASH script.  Run it from your GIT Bash Shell from within your target clone, same as you would run any git command line action.
```
$ git-filter-tab-install.sh {tabsize}
```
If no `tabsize` is provided, a default of `4` is used.

## What does it depend on?
* The tool uses `expand` and `unexpand` tools which are part of the POSIX 97 standard.
* On windows this is provided as part of `Git for Windows 2.10` or newer.

### Limitation by design - Always use Spaces Upstream
In theory the upstream repository could choose to use either tabs or spaces, but my script doesn't support it and there's no plan to add such support.  Spaces play nicer with most HTML diff viewers, and more importantly there's no need to store "tab size" metadata with the repository.  An upstream repository stored as tabs automatically requires metadata just to implicitly convert it to spaces for local user editing.  Bottom line, ***always store upstream as spaces, and users who wish to edit using tabs locally can install this script***.

### TODOs
 * Make an uninstaller
 * Add proper CLI switch support (currently it's just a quick hack to look for `--help`)
