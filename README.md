# TabSpaceFilterGit

## What does it do?
It configures a given GIT clone to perform smudge/clean filters on all tab/space characters.  Smudge/Clean filters are the same ones used to implement GIT's LF/CRLF support (via `core.auto_crlf`), and this works the same way: checkout, commit, diff, etc. all work implicitly.  The local user sees everything as either tabs or spaces (depending on user preference), while the upstream repository is stored as spaces.  It's based on proven tech -- LF/CRLF conversion is used by almost every Git for Windows client in existence and it mostly works without anyone thinking about it.

## What is it and how do I use it?
A mini-installer written in BASH script.  Run it from your GIT Bash Shell from within your target clone, same as you would run any git command line action.

To edit locally as spaces and convert errant tabs to spaces on check-in:

    $ git-filter-tab-install.sh --tabsize=4 --edit-as-spaces {repository_path}

To edit locally as tabs and convert to spaces check-in _(risky with some caveats)_:

    $ git-filter-tab-install.sh --tabsize=4 --edit-as-tabs {repository_path}

To disable the filter and restore default behavior:

    $ git-filter-tab-install.sh --edit-as-is {repository_path}

 * if no `tabsize` is provided, a default of `4` is used.
 * if `repository_path` is omitted, the curent working directory (CDW) is assumed.

## What does it depend on?
 * The tool uses `expand` and `unexpand` tools which are part of the POSIX 97 standard.
 * Windows: dependencies are provided as part of `Git for Windows 2.10` or newer.
 * OS-X: `brew install coreutils` may be required, depending on your OS version.

## Who can benefit from this tool?
Surprisingly, almost everyone!  Whether you use spaces or tabs in your local edits, you can probably benefit from this
filter.  I can't speak for everyone but no matter how hard ***I*** try, tabs somehow slip in.  Sometimes it's from
some code I copied from a website, or perhaps some snippet someone pasted to me in Slack or Pastebin.  Sometimes it seems as if
tabs just appear as if the work of some mischievous digital goblin _(one likely named Visual Studio)_.  Regardless,
these problems can be fixed effortlessly by using `git-filter-tab-install.sh --edit-as-spaces`

## What are the caveats?
#### When using `--edit-as-spaces` mode:
The only known caveat so far is that quoted text strings that depend on tabulation characters may become askew.  The 
obvious workaround is to use `"\t"` instead of an actual ASCII TAB character. It's really a case of poor development
practice anyway, and should be fixed to use `\t`.  In theory a static analyzer could be used to find such things and
report them for fixing prior to converting a repository to rely automatic tab expansion.

#### When using `--edit-as-tabs` mode:
Again the problem is quoted strings, but it's a much more serious when editing locally as tabs.  Any quoted string with
spaces will end up having tab characters inserted into it, and that will result in some very strange looking text output.
To work around this problem, the script invokes `unexpand --first-only` which limits tabulation to affect only whitespace
at the start of a line.  This also has teo notable drawbacks:

  * Multi-line strings are still affected (especially common in python and shell scripts)
  * Leading-edge whitespace tabulation is practically useless, since that's the one place that modern IDEs *already*
    behave like tab characters ehen when editing spaces (thanks to block/smart indentation)

Fixing this problem means authoring a much more intelligent version of `unexpand`, one which is capable of excluding
quoted strings from tabulation.  I've added a text file [intelligent-unexpand.md](intelligent-unexpand.md) to outline
what I think would be an ideal approach to intelligent tabulation.

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
they didn't solve problems when editing files in Notepad++ or Git Diff tools.  I've also been using Microsoft's own
`Fix Mixed Tabs` extension which is part of their Power Productiivty Suite for a long time, but i's a band-aid fix 
that operates one one file at a time, doesn't do conversion on tabs inside of lines, and is also confined only to 
Visual Studio.

Clearly a better solution would be generic to GIT itself, I thought.  It's only whitespace, after all.  Shouldn't we be 
able to handle the conversion in roughly the same way that GIT already handles CR/LF/CRLF conversions via the `core.auto_crlf` 
setting?  I did some digging and discovered that GIT exposes these automatic conversion steps via `filter.smudge` and 
`filter.clean` settings.  A few quick sandbox tests proved the concept.  This handy script followed, so that I could 
quicly apply these settings to all the clones that I work on _(which number in the dozens anymore these days)_.

I was inspired by answers found [on this StackOverflow page](https://stackoverflow.com/questions/2316677/can-git-automatically-switch-between-spaces-and-tabs) 
and decided to build a complete solution that would make it easy for me to quickly and safely apply tabspace expansion 
to any variety of projects.

----------------------------
## Other Miscellaneous Notes for the Curious

### Why doesn't this modify the project `.gitattributes` by default?
Time and energy limitations (for now).  I believe that there is value to having the `--edit-as-spaces` mode baked into a
project's `.gitattributes`.  There's a complication that I haven't yet decided a good workaround yet: distributing the 
filter configuration to users who clone the project.  Adding the various `filter=editasspaces` attributes is easy enough,
but they don't actually do anything unless the user installs the appropriate filters to git in the first place.  There are
also some caveats for order of operations.  The following steps produce the "best" results when applying this filter to a
new GIT clone (this also applies to CRLF normalization, by the way):

1. Install filters locally
2. Force GIT to re-checkout everything, using the `rm` (remove all files) method.
3. commit normalized repository
4. modify .gitattributes

If you don't follow those steps, you risk having un-normalized files in the repo which will "self-normalize" at random
times for different users during checkout/cherry-pick/merge operations.  Those kind of rendom issues can occur for weeks
or even months for some users, depending on their workflow and project activity level.  It would be ideal if the script
helps do all those things for us.

### Limitation by design - Always use Spaces Upstream
In theory the upstream repository could choose to use either tabs or spaces, but my script doesn't support it and there's
no plan to add such support.  Spaces are a lowest-common denominator of whitespace: any tabulation can be accurately represented
using spaces.  By comparison, upstream repository stored as tabs automatically requires tabsize metadata just to correctly
view it from a web viewer, or to implicitly convert it to spaces for local user editing.  Bottom line, ***always store
upstream as spaces, and users who wish to edit using tabs locally can install this script***.

### TODOs
 * Author a custom version of `unexpand` which avoids tabulating whitespace inside of quoted strings.
 * Add a --global option to apply settings globally.  Still a bit hesitant to do that.  Still too many ways this script 
   could "go wrong" if used blanketedly for all clones, I think.
 * Add feature to install filters to `.gitattributes`
 * Chocolatey package for easier distribution to clients?
 
