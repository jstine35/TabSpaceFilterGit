
Some thoughts on Intelligent tabulation of whitespace -- known as unexpand in the POSIX world.

These notes are based entirely on the preferences of people who Love Editing With Tabs.  As such,
they may not make much sense from any perspective aside from personal human preference.  In other
words, this is not an engineering paper.  It's meant for semi-cosmetic local working environments
only and should be viewed with such freedom of thought as one would view the idea of giving users
the option to use high-contrast desktop backgrounds and set ugly colors to their IDE.

### Problem case: text inside of quotes, using parsing rules matching filetype
Most languages have their own quotation rules and some are obscenely complicated  (such as `.sh`
scripts).  In terms of the simpler formats, though, this should be realistically achievable.
C/C++/C#/Python/lua for example have existing string-extraction and analysis tools which can be
borrowed for this purpose.

It might be necessary -- or at least preferable -- to simply avoid intelligent tabulation on
the more wonky formats like bash scripts, html, xml, etc.

I had also considered taking an approach of only tabulating between specific characters: punctuation
or such.  But that would still rely on avoiding tabulation of quoted strings, and a lot of my
personal C code is tabulated in situations where no punctuation is involved, such as variable
definitions.

### Problem case: Added dependency.

For sure this will add a binary dependency.  I don't think it's realistic to implement an intelligent
tabulator using a sed script.

### Action Items

 * Find some open source static string analyzers for C++, Python, Lua, etc. and see what it takes to
   tailor them to our purpose.
   
 * build a proof-of-concept and decide if they're "worth it"
 
 * Consider making a chocolately package for the new binary dependency.
 