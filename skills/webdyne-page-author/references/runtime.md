# WebDyne Runtime And Deployment

## Runtime Matrix

| Capability | Direct/Fake | Apache | PSGI | PAGI |
| --- | --- | --- | --- | --- |
| Normal PSP rendering | Yes | Yes | Yes | Yes |
| Forms, includes, blocks | Yes | Yes | Yes | Yes |
| HTMX request fragments | Yes, simulated | Yes | Yes | Yes |
| API tag processing | Yes | Explicit PSP routing | Route discovery | Route discovery |
| Server-Sent Events | No | No | No | Yes |
| WebSockets | No | No | No | Yes |

The request adapter returned by `$self->r()` presents common WebDyne operations, but transport/server details remain backend-specific. Do not assume Apache, PSGI, PAGI, and fake request objects expose identical internals.

## Direct Rendering API

Render to a scalar or scalar ref:

```perl
use WebDyne qw(html html_sr);

my $html=html("app.psp");
my $html_sr=html_sr("app.psp");
```

Supply request/render options:

```perl
my $html=html("app.psp", {
    param => {
        user => "alice",
    },
});
```

Write through an output handle:

```perl
html("app.psp", {outfile => $fh});
```

The direct/fake adapter is suitable for deterministic render tests. It is not proof of async transport behavior.

## Command-Line Rendering

Installed tools:

```bash
wdrender app.psp
wdrender --raw app.psp
wdrender --get name=Alice app.psp
wdrender --post 'name=Alice&color=red' app.psp
wdrender --htmx fragment.psp
```

Source-checkout tools when the development library is not installed:

```bash
perl -Ilib bin/wdrender app.psp
perl -Ilib bin/wdrender --raw --get name=Alice app.psp
```

Useful request modes/options:

- `--request=fake|psgi|psgi_server|pagi|mod_perl|all`
- `--root=DIR`
- `--handler=MODULE`
- `--conf=FILE`
- `--raw`
- `--header` and `--headers_in=NAME:VALUE`
- `--head_insert`
- `--repeat=NUM --compare`
- `--get`, `--post`, and `--htmx`

Use `--raw` when comparing exact output or piping it to another validator.

## PSGI And PAGI Wrappers

`WebDyne::PSGI` wraps the WebDyne request handler as PSGI. `WebDyne::PAGI` supplies ordinary HTTP handling plus PAGI SSE and WebSockets. Repository wrappers are commonly exposed through `webdyne.psgi` and `webdyne.pagi`.

Common environment:

| Variable | Purpose |
| --- | --- |
| `DOCUMENT_ROOT` | Directory or explicit source file served by PSGI/PAGI. |
| `DOCUMENT_DEFAULT` | Default page for a directory, commonly `app.psp`. |
| `WEBDYNE_CONF` | Override the global configuration file. |
| `WEBDYNE_DEBUG` | Enable all debug output with `1` or select an area/module. |
| `WEBDYNE_DEBUG_FILTER` | Regex-filter emitted debug lines. |

When the wrapper is configured with an explicit filename, that source wins over path-based dispatch. Do not set a single filename for a normal multi-page application.

PSGI/PAGI can locate API PSP files by path prefix. The filename lookup is cached in each worker, so page structure changes can require a restart.

PAGI connection handlers use a long-lived request object. Keep request state connection-local, terminate producers on disconnect/completion, and do not depend on synchronous dynamic globals after `await`.

## Apache

Apache resolves a concrete PSP file before WebDyne normally runs. Ordinary pages and explicitly routed API PSP requests work, but extensionless API fallback requires suitable rewrite/routing configuration.

Apache may run multiple worker processes. In-process page/package/cache state is local to each process and cannot substitute for shared application storage.

`WebDyne::Chain` may apply modules such as Session, Template, Static, or Cache by location. Inspect Apache/runtime directives before adding the same extension directly to a page.

## Paths And Dependencies

Relative paths for includes and page-local `require` files are based on the PSP working directory. Use `$self->cwd()` and `$self->filename()` when diagnosis requires the effective location.

A fully qualified `handler="MyApp::Page::show"` normally loads `MyApp::Page`. Ensure the application library is available through the runtime's Perl include path, application packaging, or ordinary `use lib` policy.

Do not put `-Ilib` into production page source. It is a command-line switch for testing the current repository's development modules:

```bash
prove -Ilib t/05-htmx.t
perl -Ilib bin/wdlint example.psp
```

## Configuration

The default global file is typically `/etc/webdyne.conf.pl`, overridden by `WEBDYNE_CONF`.

The configuration uses Perl/Data::Dumper-style data:

```perl
$VAR1={
    "WebDyne::Constant" => {
        WEBDYNE_CACHE_DN => "/data/webdyne/cache",
    },
    "WebDyne::Session::Constant" => {
        WEBDYNE_SESSION_ID_COOKIE_NAME => "session_cookie",
    },
};
```

Always validate it:

```bash
perl -c -w /etc/webdyne.conf.pl
```

PSGI/PAGI wrappers also load `$DOCUMENT_ROOT/.webdyne.conf.pl` when the app is built. If `DOCUMENT_ROOT` is a file, they inspect its parent directory.

Per-directory `.webdyne.conf.pl` behavior during page requests is separate and only contributes supported directory configuration when `WEBDYNE_DIR_CONFIG_CWD_LOAD` is enabled.

Configuration precedence and available constants vary by subsystem. Read the relevant `WebDyne::*::Constant` module before introducing a new setting.

## Process And Cache Semantics

Several forms of state are easy to confuse:

- Compiled page/tree/package cache: in-process and invalidated by source metadata.
- Top-level page package data: in-process, per compiled page package.
- `meta()` mutations: process-persistent for the page.
- `<perl static>` or static page output: compiled once and reused.
- `WebDyne::Cache`: rendered disk cache, requiring a cache directory.
- Session/backend data: external/shared only if its configured store is shared.

Never use in-process package variables as authoritative cross-worker state. They are appropriate for immutable initialized data, bounded memoization, or process-local diagnostics.

## Static Assets

WebDyne adapters can serve non-PSP files, but a conventional front-end web server/CDN is preferable when static asset control, caching, range requests, and throughput matter.

Keep page asset URLs consistent with the document root and mounting path. For reusable pages, avoid filesystem paths in browser-facing `href`/`src` values.

## Docker Shape

A small application commonly contains:

```text
app.psp
lib/MyApp.pm
cpanfile
Dockerfile
webdyne.conf.pl
```

Minimal image shape:

```dockerfile
FROM webdyne:latest
WORKDIR /app
COPY . .
COPY webdyne.conf.pl /etc/webdyne.conf.pl
```

Published images can expose PSGI/PAGI server controls such as worker counts, max requests, backlogs, timeouts, maximum connections, and PAGI body size. Treat those as deployment configuration, not page behavior.

## Production Checklist

- Use the runtime required by the page features; select PAGI for SSE/WebSockets.
- Make application modules and CPAN dependencies available without repository-only `-Ilib` assumptions.
- Configure a writable cache/session location where the selected extensions need one.
- Account for multiple workers when designing state and cache invalidation.
- Set proxy behavior appropriately for SSE buffering, compression, idle timeout, and reconnects.
- Restart workers after changes that affect in-process route discovery or compiled state when normal mtime invalidation is insufficient.
- Keep debug output disabled except during controlled diagnosis.
