# NAME

WebDyne - PAGI application for handling web requests

# SYNOPSIS

`webdyne.pagi [--option] <document_root>`

`webdyne.pagi --port 8080 /var/www/html`

`webdyne.pagi --test`

# DESCRIPTION

`webdyne.pagi` is a PAGI application script that handles web requests using the WebDyne framework. It builds a `WebDyne::PAGI` application, loads any configured PAGI middleware, and starts it through `PAGI::Runner`.

The underlying `WebDyne::PAGI` application can dispatch PAGI scope types for normal HTTP requests, server-sent events, WebSocket connections, and lifespan startup or shutdown events.

# OPTIONS

`webdyne.pagi` parses a small set of wrapper options itself and passes remaining command line options through to `PAGI::Runner`.

Wrapper options handled by `webdyne.pagi` itself:

**--test** Use WebDyne's internal test page as the root.

**--static / --nostatic** Enable or disable PAGI static-file middleware.

**--index / --noindex** Enable or disable index handling. With the default enabled setting, the wrapper maps the index document to WebDyne's internal default index page.

**--root** Set the document root.

**--argv** Supply additional arguments that the wrapper will prepend before invoking `PAGI::Runner`.

Remaining command line options are handled by `PAGI::Runner`. Some common options are:

**-o, --host** Which host interface to bind to. When launched through `webdyne.pagi`, the wrapper adds `--host 0.0.0.0` unless you specify a host explicitly.

**-p, --port** Which port to bind to.

**-s, --server** Which PAGI server class to use. The runner default is `PAGI::Server`.

**-E, --env** Environment mode, for example `development`, `production`, or `none`.

**-l, --loop** Event loop backend.

**-I, --lib** Add a library path to `@INC`.

**-M** Load a module before the app starts.

**--default-middleware / --no-default-middleware** Enable or disable runner default middleware.

**-D, --daemonize** Run as a background daemon.

**--access-log / --no-access-log** Configure access logging.

**--pid, --user, --group, -q, --quiet, -v, --version, --help** Standard runner process and output controls.

# EXAMPLES

To run the script for basic functionality and serve files from `/var/www/html`, use:

`webdyne.pagi /var/www/html`

Disable wrapper-managed index handling and rely on the PAGI request layer's default document behaviour instead:

`webdyne.pagi --noindex /var/www/html`

Start on another port:

`webdyne.pagi --port 8080 /var/www/html`

Start with a specific host:

`webdyne.pagi --host 127.0.0.1 --port 8080 /var/www/html`

Start with the internal test page:

`webdyne.pagi --test`

Start with a different event loop backend:

`webdyne.pagi --loop EV /home/aspeer/public_html`

# ENVIRONMENT VARIABLES

This script is a frontend to the WebDyne PAGI stack. It uses WebDyne configuration and environment handling, including `DOCUMENT_ROOT`, `DOCUMENT_DEFAULT`, and the relevant `WEBDYNE_*` settings used by the PAGI modules.

When launched from the command line, the wrapper also reads local WebDyne configuration from `DOCUMENT_ROOT/.webdyne.conf.pl` before starting the PAGI runner.

Relevant PAGI-specific settings from `WebDyne::PAGI::Constant` include:

**WEBDYNE_PAGI_STATIC** Enable or disable static-file serving middleware.

**WEBDYNE_PAGI_MIDDLEWARE_STATIC** Regular expression used to decide which static files are served directly.

**WEBDYNE_PAGI_MIDDLEWARE** Middleware stack applied around the WebDyne PAGI app.

**WEBDYNE_PAGI_ENV_KEEP / WEBDYNE_PAGI_ENV_SET** Environment variables preserved or injected for request handling.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
