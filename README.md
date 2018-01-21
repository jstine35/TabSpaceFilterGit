# TabSpaceFilterGit

## What does it do?
It configures a given GIT clone to perform smudge/clean filters on all tab/space characters.  Smudge/Clean filters
work on the same principle as the filter used to implement GIT's LF/CRLF support (via `core.auto_crlf`), and this
works the same way: checkout, commit, diff, etc. all work implicitly.  The local user sees everything as either
tabs or spaces (depending on user preference), while the upstream repository is stored as spaces.  It's based on
proven tech -- LF/CRLF conversion is used by almost every Git for Windows client in existence and it mostly works
without anyone thinking about it.

## What does this software depend on?
 * The tool uses `expand` and `unexpand` tools which are part of the POSIX 97 standard
 * the shell scripts require at minimum BASH 4.0+

#### to sum up by platform:
 * Linux: everything should be in place already.  Enjoy!
 * Windows: dependencies are provided as part of `Git for Windows 2.10` or newer
 * OS-X: `brew install coreutils` may be required, depending on your OS version

## How do I use it?
* Step 1. run the filter config installer
* Step 2. add TabSpace normalization rules to your projects
* Step 3. _(optional)_ normalize the whitespace for your existing repository
* Step 4. _(optional)_ check in `.gitattributes` with TabSpace normalization rules

### Step 1. Run the filter installer
The installer and normalizer utilities are BASH scripts.  Run them from your GIT Bash Shell from within your target
clone, same as you would run any git command line action.  The recommended method is to start by modifying a couple
repositories locally and then, if you find it to be working well, apply the settings globally.

To edit locally as spaces and convert errant tabs to spaces on check-in:

    $ git-tabspace-config.sh --tabsize=4 --edit-as-spaces [--global|--local] [local_repository_path]

To edit locally as tabs and convert to spaces check-in _(risky with caveats)_:

    $ git-tabspace-config.sh --tabsize=4 --edit-as-tabs [--global|--local] [local_repository_path]

To remove the filter and restore default git behavior (or default global behavior is applied locally):

    $ git-tabspace-config.sh --remove [--global|--local] [local_repository_path]

To forcibly disable the filter on a local repository, overriding global settings:

    $ git-tabspace-config.sh --disable-local [repository_path]

 * if `tabsize` is omitted, a default of `4` is used.
 * global is default if neither `--global` or `--local` is specified
 * `local_repository_path` is only relevant if `--local` is specified
 * if `local_repository_path` is omitted, the current working directory (CWD) is assumed
 * `--uninstall` and `--remove` are aliases

### Step 2. Add TabSpace normalization rules to your projects

There are two ways to add TabSpace normalization rules to your project.

#### As a contributor or when forking:
 * If you are contributing to a project that you don't own outright then the recommended method is to modify the 
   unchecked `.git/info/attributes` file.  This will apply filtering rules for just you alone and will not alter
   upstream behavior.

#### As an owner:
 * As an owner of a project the best way should be to modify `.gitattributes` directly and push it upstream.  
   It is recommended as a second step to add the TabFilter installer, either via npm or nuget package, to ensure
   contributors have the filters configured.  The `.gitattributes` filter specifications will be ignored for users
   that do not have the TabSpace filters configured.

A sample set of attributes can be viewed on the repository:
 * https://github.com/jstine35/TabSpaceFilterGit/blob/master/gitattributes.sample

A helper script is also provided which can write that same file on the command line or clipboard, or copy it into
the local `.git/info/attributes` for you.

***Note*** `git-tabspace-attrib.sh` provides a nice starting point/template, but there are a great number of
common file extensions still missing from the sample attributes file.  These days there's more `.config` style
files than anyone can count, and so ___there's a good chance you'll need to edit the attributes by hand regardless___.

To write contents to stdout or clipboard:

    $ git-tabspace-attrib.sh --print
    $ git-tabspace-attrib.sh --clip

To append contents to existing `.gitattributes`, use the bash pipe for append (`>>`):

    $ git-tabspace-attrib.sh -p >> .gitattributes

If no parameters are specified, the script will automatically copy the sample attributes file into the
`.git/info/attributes` or report a problem if the file already exists and is not empty -- in which case
the file will need to be updated manually.

### Step 3. Normalize whitespace for your repository

_This section is mostly specific to project owners.  Contributors can mostly get away without full repository-wide
normalization, though at the cost of occasionally having GIT randomly and inconveniently normalize files in 
places you never touched._

See `git-tabspace-normalize.sh --help`

#### What happens if I don't normalize the repository?

You risk having un-normalized files in the repo which will "self-normalize" at random times for different users
during checkout/cherry-pick/merge operations.  Those kind of rendom issues can occur for weeks or even months for
some users, depending on their workflow and project activity level.  This can cause cherry pick and rebase operations
to fail in an unresolvable manner where every attempt to stash or revert the auto-normalized file results in the 
file re-normalizing.  This is a common problem already when using GIT's built-in Auto-CRLF feature.


___[todo section]___

-------------------

## Who can benefit from this tool?
Surprisingly, almost everyone!  Whether you use spaces or tabs in your local edits, you can probably benefit from
this filter.  I can't speak for everyone but no matter how hard ***I*** try, tabs somehow slip in.  Sometimes it's
from some code I copied from a website, or perhaps some snippet someone pasted to me in Slack or Pastebin. 
Sometimes it seems as if tabs just appear as if the work of some mischievous digital goblin _(one likely named Visual
Studio)_.  Regardless, these problems can be fixed effortlessly by using `git-filter-tab-install.sh --edit-as-spaces`

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

----------------------------
## Other Miscellaneous Notes for the Curious

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
quickly apply these settings to all the clones that I work on _(which number in the dozens anymore these days)_.

I was inspired by answers found [on this StackOverflow page](https://stackoverflow.com/questions/2316677/can-git-automatically-switch-between-spaces-and-tabs) 
and decided to build a complete solution that would make it easy for me to quickly and safely apply tabspace expansion 
to any variety of projects.

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
 
