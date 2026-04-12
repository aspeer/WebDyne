# wdlint(1) #

# NAME #

wdlint - check Perl syntax in the `__PERL__` section of a WebDyne file

# SYNOPSIS #

`wdlint [PERL_OPTIONS] FILE`

# Description #

The `wdlint` command checks the Perl syntax embedded in a WebDyne `.psp` file.

It does this by copying the source file to a temporary file, scanning until it finds the `__PERL__` marker, then inserting a Perl shebang, `use strict;`, and a `#line` directive so any syntax errors reported by Perl refer back to the original source file and line numbers as closely as possible.

It then runs:

```sh
perl -c -w -x
```

against the temporary file and prints any warnings or syntax errors returned by Perl.

This utility is primarily useful for checking server-side Perl code in the `__PERL__` section of a WebDyne page. It is not a full WebDyne page validator and it does not check the HTML structure, WebDyne compilation stages, or runtime behaviour of the page.

# Options #

`wdlint` does not implement its own option parser. The last argument is treated as the source file to check. Any earlier arguments are passed directly through to Perl when running the syntax check.

In practice this means:

* Perl warnings are enabled by default via `-w`

* Perl syntax checking is enabled by default via `-c`

* Perl `-x` processing is enabled so Perl starts reading from the injected Perl section

* any additional arguments before the file name are passed directly to Perl, for example `-I` include paths or other Perl switches

# Examples #

```html
<start_html>
Hello World <? server_time() ?>
__PERL__

sub server_time {
    my 2==1; # Error here
}
```

```sh
# Check the embedded Perl syntax in a WebDyne page
#
$ wdlint check.psp
syntax error at check.psp line 6, near "my 2"
check.psp had compilation errors.
```

```sh
# Pass an include path through to Perl while checking syntax
#
$ wdlint -Ilib page.psp
```

# Notes #

Only the Perl code after the `__PERL__` marker is linted. If a file contains no `__PERL__` section, the command still constructs a temporary file and runs Perl against it, but there may be little or nothing useful to validate.

`wdlint` adds `use strict;` to the temporary file during checking, so code that only compiles without strict mode may fail under `wdlint`.

Because the command relies on Perl's own parser, it is a good tool for catching syntax mistakes early, but it will not detect WebDyne-specific logic errors, bad HTML, or problems that only appear when the page is compiled or rendered in a real request context.

# Author #

Written by Andrew Speer,  <andrew@webdyne.org>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright \(c) 2026 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/&gt;
