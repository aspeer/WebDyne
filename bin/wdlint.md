# wdlint #

# NAME #

wdlint - check Perl syntax embedded in a WebDyne file

<a name="wdlint-synopsis"></a>

# SYNOPSIS #

`wdlint [PERL_OPTIONS] FILE`

<a name="wdlint-description"></a>

# Description #

The  wdlint  command checks the Perl syntax embedded in a WebDyne  .psp  file.

It does this by compiling the page to WebDyne stage 0, collecting embedded Perl fragments, then writing those fragments to temporary Perl files with `#line` directives so syntax errors reported by Perl refer back to the original source file and line numbers as closely as possible. Inline fragments are checked separately so one syntax error does not hide later errors in other fragments.

It then runs:

```bash
perl -c -w

```

against the temporary file and prints any warnings or syntax errors returned by Perl.

This utility is primarily useful for checking server-side Perl code in `__PERL__`, inline `<perl>` blocks, processing instructions, and substitution expressions. It is not a full WebDyne page validator and it does not check runtime behaviour of the page.

<a name="wdlint-options"></a>

# Options #

wdlint  does not implement its own option parser. The last argument is treated as the source file to check. Any earlier arguments are passed directly through to Perl when running  the syntax check.

In practice this means:

*  Perl warnings are enabled by default via  -w .

*  Perl syntax checking is enabled by default via -c .

*  Any additional arguments before the file name are passed directly to Perl, for example include paths or other Perl switches.

<a name="wdlint-examples"></a>

# Examples #

```html
# Sample psp file with deliberate error, save as check.psp
#
<start_html>
Hello World <? server_time() ?>
__PERL__

sub server_time {
    my 2==1; # Error here
}
```

```bash
# Check the embedded Perl syntax in a WebDyne page
#
$ wdlint check.psp
syntax error at check.psp line 6, near "my 2"
check.psp had compilation errors.
```

```bash
# Pass an include path through to Perl while checking syntax
#
$ wdlint -I/path/to/lib page.psp
```

<a name="wdlint-notes"></a>

# Notes #

wdlint relies on WebDyne's stage 0 compiler to find embedded Perl. If a file contains no embedded Perl, the command still constructs a minimal temporary file and runs Perl syntax checking against it.

The temporary file is removed after the Perl syntax check completes.

wdlint  adds  `use strict;`  to the temporary file during checking, so code that only compiles without strict mode may fail under  wdlint .

Because the command relies on Perl's own parser, it is a good tool for catching syntax mistakes early, but it will not detect WebDyne-specific logic errors, bad HTML, or problems that only appear when the page is compiled or rendered in a real request context.

<a name="wdlint-author"></a>

# Author #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
