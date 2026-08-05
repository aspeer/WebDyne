# WebDyne Runtime Notes

## File Type

WebDyne pages normally use the `.psp` extension. A `.psp` page is HTML with WebDyne tags and embedded Perl. It can run under Apache/mod_perl, PSGI, PAGI, Docker, or standalone render helpers.

## Standalone Rendering

The module can render pages directly:

```perl
use WebDyne qw(html html_sr);

my $html = html('app.psp');
my $html_ref = html_sr('app.psp');
```

Pass page parameters:

```perl
my $html = html('app.psp', {
    param => {
        user => 'alice',
    },
});
```

Write rendered output:

```perl
html('template.psp', { outfile => $fh });
```

## Command-Line Runtime

Use `wdrender` to render a `.psp` page:

```bash
wdrender app.psp
wdrender --get name=Alice app.psp
wdrender --post 'name=Alice&color=red' app.psp
wdrender --htmx fragment.psp
wdrender --header app.psp
```

Useful options:

- `--request=fake|psgi|psgi_server|pagi|mod_perl|all`
- `--root=DIR`
- `--handler=MODULE`
- `--conf=FILE`
- `--raw`
- `--head_insert`
- `--repeat=NUM --compare`

## PSGI/PAGI

`WebDyne::PSGI` wraps the core WebDyne handler in a PSGI app. Common wrapper use is via `webdyne.psgi`.

Important environment variables:

- `DOCUMENT_ROOT`: root directory or file for PSGI/PAGI wrappers.
- `DOCUMENT_DEFAULT`: default file in a directory, commonly `app.psp`.
- `WEBDYNE_CONF`: alternate config file.
- `WEBDYNE_DEBUG`: module or area debug selector.
- `WEBDYNE_DEBUG_FILTER`: regex filter for debug output.

## Config Files

WebDyne looks for `/etc/webdyne.conf.pl` unless overridden. The PSGI/PAGI wrappers also load `DOCUMENT_ROOT/.webdyne.conf.pl` when the app is built, whether started directly or loaded by an external server. If `DOCUMENT_ROOT` is a file, the parent directory is checked. Per-request `.webdyne.conf.pl` files in PSP directories are separate and only contribute `WEBDYNE_DIR_CONFIG` when `WEBDYNE_DIR_CONFIG_CWD_LOAD` is enabled.

The file is Perl Data::Dumper-style data:

```perl
$VAR1 = {
    'WebDyne::Constant' => {
        WEBDYNE_CACHE_DN => '/data1/webdyne/cache',
    },
    'WebDyne::Session::Constant' => {
        WEBDYNE_SESSION_ID_COOKIE_NAME => 'session_cookie',
    },
};
```

Always validate config syntax:

```bash
perl -c -w /etc/webdyne.conf.pl
```

## Docker App Shape

A WebDyne Docker app commonly has:

```text
app.psp
app.pm
cpanfile
Dockerfile
webdyne.conf.pl
```

Minimal app Dockerfile:

```dockerfile
FROM webdyne:latest
WORKDIR /app
COPY app.* .
COPY cpanfile .
COPY webdyne.conf.pl /etc
```

Run with an explicit port:

```bash
docker run -e PORT=5010 -p 5010:5010 webdyne-app
```

## Docker Server Tuning

Published WebDyne images expose server tuning variables:

- `WEBDYNE_SERVER_PSGI_WORKERS`
- `WEBDYNE_SERVER_PSGI_MAX_REQUESTS`
- `WEBDYNE_SERVER_PSGI_BACKLOG`
- `WEBDYNE_SERVER_PSGI_KEEPALIVE_TIMEOUT`
- `WEBDYNE_SERVER_PSGI_READ_TIMEOUT`
- `WEBDYNE_SERVER_PAGI_WORKERS`
- `WEBDYNE_SERVER_PAGI_MAX_REQUESTS`
- `WEBDYNE_SERVER_PAGI_LISTENER_BACKLOG`
- `WEBDYNE_SERVER_PAGI_TIMEOUT`
- `WEBDYNE_SERVER_PAGI_REQUEST_TIMEOUT`
- `WEBDYNE_SERVER_PAGI_MAX_CONNECTIONS`
- `WEBDYNE_SERVER_PAGI_MAX_BODY_SIZE`
