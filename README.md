# TabSpaceFilterGit

## What does it do?
It configures a given GIT clone to perform smudge/clean filters on all tab/space characters.  Smudge/Clean filters are the same ones used to implement GIT's LF/CRLF support (via `core.auto_crlf`), and this works the same way: checkout, commit, diff, etc. all work implicitly.  The local user sees everything as either tabs or spaces (depending on user preference), while the upstream repository is stored as spaces.  It's based on proven tech -- LF/CRLF conversion isalrwady used by almost every Git for Windows client in existence.

## What is it and how do I use it?
A mini-installer written in BASH script.  Run it from your GIT Bash Shell from within your target clone, same as you would run any git command line action.

To edit locally as tabs and convert to spaces upstream:

    $ git-filter-tab-install.sh --tabsize=4 --edit-as-tabs {repository_path}

To edit locally as spaces and convert errant tabs to spaces upstream:

    $ git-filter-tab-install.sh --tabsize=4 --edit-as-spaces {repository_path}

To disable the filter and restore default  behavior:

    $ git-filter-tab-install.sh --edit-as-is {repository_path}```

* if no `tabsize` is provided, a default of `4` is used.
* if `repository_path` is omitted, the curent working directory (CDW) is assumed.

## What does it depend on?
* The tool uses `expand` and `unexpand` tools which are part of the POSIX 97 standard.
* On windows this is provided as part of `Git for Windows 2.10` or newer.

## Who can benefit from this tool?
Surprisingly, almost everyone!  Whether you use spaces or tabs in your local edits, you can probably benefit from this
filter.  I can't speak for everyone but no matter how hard ***I*** try, tabs somehow slip in.  Sometimes it's from
some code I copied from a website, or perhaps some snippet someone pasted to me in Slack.  Sometimes it seems as if
tabs just appear as if the work of some mischievous digital goblin.  Regardless, these problems can be fixed
effortlessly by using `git-filter-tab-install.sh --edit-as-spaces`

## What are the caveats?
The only known caveat so far is that quoted text that depends on tabulation characters would be corrupted by this filter.
The obvious workaround is to use `"\t"` instead of an actual ASCII TAB code.  It's highly unlikely any modern code would
run into this problem and, if it did, it's really a case of poor development practice anyway, and should be fixed to use
`\t`.  In theory a static analyzer could be used to find such things and report them for fixing prior to converting a
repository to rely automatic tab expansion.

## Why does it exist?
One of the grand old conundrums of programming and code etiquette is ***"Tabs or Spaces?"*** - 
This question is often complicated by a slew of popular editors on both Windows and Linux platforms with
dodgy support of tab alignment (_linux_), or dodgy support of *disabling* tabs (_Visual Studio_).  This handy
script aims to solve them all, by eloquently allowing devs who prefer tabs to use their precious tabs, while 
allowing the upstream copy of files to be managed using the lowest common denominator of whitespace alignment:
_*The Holy Space*_.

I didn't come to this solution quickly.  I tried various Visual Studio extensions, several of which promised
me the ability to edit space-expanded source files as if there were tab characters -- eg, navigating four spaces at
a time via arrow keys and such.  These either worked poorly or didn't work at all after a Visual Studio update, and
they didn't solve problems when editing files in Notepad++ or Git Diff tools.  I've also been using Microsoft's own `Fix Mixed Tabs` extension which is part of their Power Productiivty Suite for a long time, but i's a band-aid fix that operates one one file at a time, doesn't do conversion on tabs inside of lines, and is also confined only to Visual Studio.

Clearly a better solution would be generic to GIT itself, I thought.  It's only whitespace, after all.  Shouldn't we beable to handle the conversion in roughly the same way that GIT already handles CR/LF/CRLF conversions via the `core.auto_crlf` setting?  I did some digging, discovered that GIT exposes these automatic conversion steps via `filter.smudge` and `filter.clean` settings.  A few quick sandbox tests proved the concept.  This handy script followed, so that I could quicly apply these settings to all the clones that I work on _(which number in the dozens anymore these days)_.

----------------------------

### Limitation by design - Always use Spaces Upstream
In theory the upstream repository could choose to use either tabs or spaces, but my script doesn't support it and there's no plan to add such support.  Spaces play nicer with most HTML diff viewers, and more importantly there's no need to store "tab size" metadata with the repository.  An upstream repository stored as tabs automatically requires metadata just to implicitly convert it to spaces for local user editing.  Bottom line, ***always store upstream as spaces, and users who wish to edit using tabs locally can install this script***.

### TODOs
* Add a --global option to apply settings globally.  Still a bit hesitant to do that.  Still too many ways this script could "go wrong" if used blanketedly for all clones, I think...
