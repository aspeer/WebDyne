
# NAME

WebDyne - PSGI application for handling web requests

# SYNOPSIS

`webdyne.psgi [--option] <document_root>`

`webdyne.psgi --port 8080 /var/www/html` 

`webdyne.psgi --test`

# DESCRIPTION

`webdyne.psgi` is a PSGI application script that handles web requests using the WebDyne framework. It initializes the environment, creates a new PSGI request object, determines the appropriate handler, and processes the request to generate a response.

# OPTIONS

`webdyne.psgi` parses a small set of wrapper options itself and passes remaining command line options through to `Plack::Runner`.

Wrapper options handled by `webdyne.psgi` itself:

**--test** Use WebDyne's internal test page as the root.

**--static / --nostatic** Enable or disable PSGI static-file middleware.

**--index / --noindex** Enable or disable index handling. With the default enabled setting, the wrapper maps the index document to WebDyne's internal default index page.

**--root** Set the document root.

**--argv** Supply additional arguments that the wrapper will prepend before invoking `Plack::Runner`.

Remaining command line options are handled by `Plack::Runner` and are the same as described in the [plackup(1)](man:plackup(1)) man page. Refer to that page for full options but some common options are:

**--host** Which host interface to bind to

**--port** Which port to bind to

**--server** Which server to use, e.g. Starman

**--reload** Reload if libraries or other files change

**-I** Same as perl -I for library include paths

**-M** Same as perl -M for loading modules before the script starts


# EXAMPLES

To run the script, use the following command for basic functionality and serving files from the /var/www/html directory. With default settings, index handling is enabled and the wrapper uses WebDyne's internal default index page.

`webdyne.psgi /var/www/html`

Disable wrapper-managed index handling and rely on the PSGI request layer's default document behaviour instead

`webdyne.psgi --noindex /var/www/html`

Start with the Starman server

`webdyne.psgi --no-default-middleware --server Starman /home/aspeer/public_html`

Start with the internal test page

`webdyne.psgi --test`

# ENVIRONMENT VARIABLES

This script is a frontend to the WebDyne PSGI stack. In addition to `Plack::Runner` options, it uses WebDyne configuration and environment handling, including `DOCUMENT_ROOT`, `DOCUMENT_DEFAULT`, and the relevant `WEBDYNE_*` settings used by the PSGI modules.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
