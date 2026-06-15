INSTALL

# Installation via CPAN #

Install the base WebDyne module, and its core prerequisites, with:

```bash
perl -MCPAN -e 'install WebDyne'
```

or, on systems using `cpanm`:

```bash
cpanm WebDyne
```

This installs the core modules and command-line tools. Depending on the runtime you want to use, you may also need PSGI/Plack, PAGI, or Apache/mod_perl components.

Full documentation is available in the `doc` directory and at [https://webdyne.org](https://webdyne.org).

# PSGI / Plack #

To use WebDyne through PSGI, install Plack and any PSGI server you want to run:

```bash
cpanm Plack
```

You can then validate the wrapper with:

```bash
webdyne.psgi --test
```

or serve a document root:

```bash
webdyne.psgi /path/to/site-root
```

# PAGI #

To use WebDyne through PAGI, install the PAGI runtime stack required by your chosen PAGI server.

You can then validate the wrapper with:

```bash
webdyne.pagi --test
```

or serve a document root:

```bash
webdyne.pagi /path/to/site-root
```

The PAGI runtime supports normal HTTP requests as well as server-sent event, WebSocket, and lifespan flows.

# Apache / mod_perl #

For permanent Apache/mod_perl configuration, use the Apache installer:

```bash
wdapacheinit
```

It uses reasonable defaults to locate and update Apache configuration and WebDyne cache directories. Run `wdapacheinit --help` to review available options before changing a system Apache installation.

For temporary local development and troubleshooting under Apache/mod_perl, use:

```bash
webdyne.apache --test
```

or serve a local document root:

```bash
webdyne.apache /path/to/site-root
```

# Installation via Manual Build #

After unpacking the source tree, build and install with:

```bash
perl Makefile.PL
make
make test
make install
```

Modules required by the selected build and runtime path should be reported when you run `perl Makefile.PL`. As with a CPAN install, you still need to configure or start the appropriate runtime wrapper before WebDyne pages will be served.
