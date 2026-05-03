# wdrender(1) #

# NAME #

wdrender - parse and render WebDyne files

# SYNOPSIS #

`wdrender [OPTIONS] FILE`

# DESCRIPTION #

`wdrender` renders a WebDyne source file and prints the resulting response body to standard output.

By default it uses the internal `WebDyne` handler with the `fake` request backend. It can also exercise other backends such as `psgi`, `psgi_server`, `pagi`, and `mod_perl`, or use a different handler module via `--handler`.

Defaults:

* request backend: `fake`
* method: `GET`
* root: current working directory
* colour: enabled
* line numbers: enabled
* tidy formatting: enabled
* theme: `light`

Options can also be preloaded from `~/.wdrender.opt` by creating an anonymous hash of option names and values.

# OPTIONS #

## General ##

* **-h, --help**

    Show brief help output \(synopsis and options).

* **--man**

    Display the full manual.

* **--version**

    Display the script version and WebDyne version, then exit.

* **--handler=MODULE**

    Use a different WebDyne handler module, for example `WebDyne::Chain`.

* **--conf=FILE, --config=FILE**

    Set `WEBDYNE_CONF` to the specified configuration file before rendering.

* **--noconf, --noconfig, --no_conf, --no_config, --no-conf, --no-config**

    Disable normal config loading by setting `WEBDYNE_CONF=.`.

* **--raw**

    Disable config loading and skip HTML tidy/colour formatting.

* **--outfile=FILE**

    Send output to nominated file. Colourisation is disabled but tidy will be performed if available.
    
* **--warn / --nowarn**
    Enable or disable warnings about missing Tidy or Colourise modules

## Backend Selection ##

* **--request=TYPE, -r TYPE**

    Select the backend used to execute the request. Valid values in the current script are `fake`, `psgi`, `psgi_server`, `pagi`, and `mod_perl`.

* **--fake**

    Shortcut for `--request=fake`.

* **--psgi**

    Shortcut for `--request=psgi`.

* **--psgi_server**

    Shortcut for `--request=psgi_server`.

* **--pagi**

    Shortcut for `--request=pagi`.

* **--mod_perl, --apache**

    Shortcut for `--request=mod_perl`.

* **--all**

    Run all supported backends instead of just one selected backend.

* **--root=DIR, --docroot=DIR, --doc_root=DIR, --document_root=DIR**

    Set the document root passed to backend handlers. Defaults to the current working directory.

* **--keep_tmp**

    When using the `mod_perl` backend, do not cleanup temporary Apache server root.

## Request Construction ##

* **--method=VERB**

    Explicitly set the HTTP method, for example `GET`, `POST`, `PUT`, `PATCH`, `OPTIONS`, or `HEAD`.

* **--get=KEY=VALUE**

    Add request parameters and use `GET`.

* **--post=KEY=VALUE**

    Add request parameters and use `POST`.

* **--put=KEY=VALUE**

    Add request parameters and use `PUT`.

* **--patch=KEY=VALUE**

    Add request parameters and use `PATCH`.

* **--options=KEY=VALUE**

    Add request parameters and use `OPTIONS`.

* **--head**

    Use `HEAD`.

* **--param=KEY=VALUE**

    Pass handler parameters to the WebDyne handler call. These are separate from request query/body parameters and are available to handler-side Perl code.

* **--headers_in=NAME:VALUE, --header_in=NAME:VALUE**

    Add request headers. Multiple values may be supplied by repeating the option.

* **--htmx**

    Add the request header `HX-Request: true`.

* **--sse**

    Add the request header `Accept: text/event-stream`.

## Response Display ##

* **--header, --headers**

    Include the response status line and headers ahead of the rendered body.

* **--header_only, --header-only, --headers_only, --headers-only, --headersonly**

    Print only the response status line and headers.

* **--colour, --color / --nocolour, --nocolor**

    Enable or disable HTML syntax highlighting for `text/html` responses.

* **--lineno / --nolineno**

    Enable or disable line numbers in colourised output.

* **--theme=light|dark**

    Select the colour theme used by syntax highlighting.

* **--tidy, --pretty / --notidy, --nopretty**

    Enable or disable HTML tidy formatting for `text/html` responses. Tidy is skipped automatically for HTMX output.

## Repetition and Comparison ##

* **--repeat=NUM, --num=NUM, --n=NUM**

    Repeat the render `NUM` times.

* **--compare**

    When repeating renders, require each rendered body to match the first one. If output differs, the script aborts and shows a diff when `Text::Diff` is installed.

* **--loop**

    Repeat forever. Intended for leak or stability testing.

* **--delay=SECONDS, --sleep=SECONDS**

    Sleep between iterations.

# EXAMPLES #

```sh
# Show the rendered version of time.psp
wdrender time.psp
```

```sh
# Show headers as well as the body
wdrender --header time.psp
```

```sh
# Show only the status line and headers
wdrender --header-only time.psp
```

```sh
# Render using a different handler
WebDyneChain=WebDyne::Session wdrender --handler WebDyne::Chain time.psp
```

```sh
# Simulate a GET request with query parameters
wdrender --get "test=1" checkbox.psp
```

```sh
# Simulate a POST request
wdrender --post "name=alice" form.psp
```

```sh
# Force the PSGI backend
wdrender --psgi app/example.psp
```

```sh
# Compare repeated renders for stability
wdrender --repeat 5 --compare page.psp
```

```sh
# Simulate an HTMX request with a custom header
wdrender --htmx --headers_in "X-Debug: 1" fragment.psp
```

# NOTES #

`wdrender` aims to reproduce WebDyne output from the command line, but it cannot perfectly duplicate every web-server runtime detail. In particular, pages that depend on a specific server environment may behave differently across `fake`, `psgi`, `pagi`, and `mod_perl` backends.

# AUTHOR #

Written by Andrew Speer, <andrew@webdyne.org>

# LICENSE AND COPYRIGHT #

This file is part of WebDyne.

This software is copyright \(c) 2026 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/&gt;
