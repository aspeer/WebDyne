## WebDyne - Perl embedded HTML engine and mod_perl/PSGI/PAGI web framework

**WebDyne** is a Perl-centric dynamic HTML engine for building server-rendered web applications with embedded Perl. It has been updated to support modern Perl web runtimes while preserving the original `.psp` page model.

It supports multiple Perl embedding styles inside `.psp` files, partial compilation and caching for performance, and runs under **mod_perl**, **PSGI/Plack**, or **PAGI**.

WebDyne 3.0 brings the established `.psp` page model to synchronous and
asynchronous Perl servers. This overview covers notable changes across the 3.x
series; see [Changes.md](Changes.md) for individual releases.

Full documentation is at [webdyne.org](https://webdyne.org), with packages on
[CPAN](https://metacpan.org/dist/WebDyne), source on
[GitHub](https://github.com/aspeer/WebDyne), and Docker images for deployment.

### WebDyne 3.0 highlights

- **Three server runtimes.** Run pages under Apache/mod_perl, PSGI/Plack, or
  PAGI, with normalized request adapters and helper scripts for each runtime.
  `webdyne.apache` can start a temporary local server without installing a
  permanent Apache configuration.
- **Asynchronous applications.** PAGI supports HTTP, server-sent events,
  WebSockets, and application lifespan events. SSE and WebSocket handlers can
  receive parsed parameters and render WebDyne fragments for browser updates.
- **HTML fragments and JSON APIs.** HTMX handlers and reusable blocks support
  partial page updates. API pages use Router::Simple routes relative to their
  own mount path, so route declarations can move with the application.
- **Page authoring and diagnostics.** `<start_html>` supports dependency loading
  and imports. `wdlint` checks embedded Perl chunks and substitutions as well
  as `__PERL__` sections. Compiler, renderer, wrapper, and tag documentation
  accompany the examples and integrated main documentation.
- **Safer defaults.** Request-derived substitutions and CGI-generated values
  gain automatic HTML escaping. Session cookies have Secure, HttpOnly, and
  SameSite defaults. Directory indexing, source viewing, and PSGI/PAGI static
  serving require explicit configuration; API path traversal and PSP extension
  checks have also been tightened.
- **More reliable request handling.** Recent fixes preserve repeated cookies
  and headers, support forms without Content-Length and media-type charset
  parameters, and bound request bodies. PAGI multipart uploads, mounted paths,
  SSE completion and setup denials, and WebSocket handshake rejection have
  dedicated regression coverage.
- **Portable caching.** Source, template, and compiled-cache handling accepts
  valid zero timestamps, including those used by WebAssembly filesystems.

### Upgrading an existing application

- Since 3.020, `<api pattern>` matches the path relative to the API page's
  mount. An API page mounted at `/api` should declare `/user/:id` rather than
  `/api/user/:id`.
- Review uses of automatic escaping and reserve raw `${...}` substitutions for
  trusted rendered content. Secure session cookies require HTTPS; configure
  cookie attributes explicitly where local development needs different values.
- Enable indexing, source viewing, or static-file serving explicitly where
  needed. Wrapper and application-builder defaults are intentionally conservative.
- `WEBDYNE_CGI_POST_MAX` defaults to 512 KiB and now bounds buffered PAGI and
  PSGI HTTP bodies, including non-form content. Increase it explicitly for
  applications accepting larger payloads. Under Apache, configure
  `LimitRequestBody 524288` as primary protection and keep it consistent with
  the WebDyne limit. Uncaught Apache adapter validation exceptions currently
  produce HTTP 500.
- PAGI SSE setup supports bounded URL-encoded forms. Multipart SSE submissions
  remain unsupported; use a normal HTTP upload endpoint for those forms.

The examples below introduce the page syntax, fragments, APIs, and runtime tools.

---

### Perl

Perl code can be embedded or called from a HTML page. Hello world type example:

```html
<start_html>
The local server time is: <? localtime() ?>
```

[Run](https://demo.webdyne.org/introduction2.psp)

The <start_html> tag is an optional shortcut - standard HTML is generated as output, and you can still use standard HTML tags if desired. These are all working syntax variations for embedding perl code into a HTML page. Note the use of the \_\_PERL\_\_ token to designate the end of the HTML page and start of (optional) page code.

```html
<start_html>
Server time is:
<pre>
<!-- tagged inline -->
<perl> localtime() </perl>

<!-- processing instructions -->
<? localtime() ?>

<!-- substitution -->
!{! localtime() !}

<!-- server side script -->
<script type="application/perl"> localtime() </script>

<!-- subroutine, direct output -->
<perl handler="time1"/>

<!-- subroutine, templated output -->
<perl handler="time2">
${time}
</perl>

</pre>
__PERL__
sub time1 { return localtime }
sub time2 { return shift()->render( time=>scalar localtime() ) }
```

[Run](https://demo.webdyne.org/release1.psp)

---

### Blocks

Blocks of text or html are supported for conditional rendering of page components.

```html
<start_html>
<p>
<perl handler=greeting>
<block name="morning">
Good morning, it is <? localtime ?>
</block>
<block name="evening">
Good evening, it is  <? localtime ?>
</block>
</perl>

__PERL__
sub greeting {
    my $self=shift();
    if ((localtime)[2] < 12) {
        $self->render_block('morning')
    }
    else {
        $self->render_block('evening')
    }
    return $self->render()
}
```

[Run](https://demo.webdyne.org/release2.psp)

Blocks can be nested and used for creating tables etc. 

------

### HTMX

One of the more interesting features - it can work with [htmx](https://htmx.org) by returning HTML fragments. This example shows everything in one page but htmx calls can be separated into their own pages if desired.

```html
<start_html script="https://unpkg.com/htmx.org@1.9.10">
Click button for current server time:
<button hx-get="#" hx-target="#time">Refresh</button>
<p>
<div id="time"><em>Time Not Loaded Yet</div>
<htmx perl>
return localtime
</htmx>
```

[Run](https://demo.webdyne.org/htmx_time4.psp)

---

### JSON

WebDyne can embed server generated JSON into output pages (within a &lt;script&gt;&lt;/script&gt; container)  to be used by client side Javascript. In this case the &lt;json&gt; tag will render into a &lt;script&gt; block of JSON data that will be used to drive a chart.

```html 
<start_html>
Mini Chart:
<p>
<canvas id="c" width="120" height="60"></canvas>
<json id=data handler=chart/>
<script>
  let d = JSON.parse(data.textContent), x = c.getContext("2d");
  x.fillStyle = "green";
  d.forEach((v, i) => x.fillRect(i*30, 60 - v*5, 20, v*5));
</script>

__PERL__

sub chart {
    my @data=(5, 12, 9, 7);
    return \@data
}
```

[Run](https://demo.webdyne.org/release3.psp)

------

### API Mode

Supports a lightweight API mode where JSON is returned in response to `Router::Simple` path matches

```html 
<api handler="change_case" pattern="/{user}"/>
__PERL__
sub change_case {
    my ($self, $api_hr)=@_;
    my %data=(
        uppercase => uc($api_hr->{'user'}),
        lowercase => lc($api_hr->{'user'})
    );
    return \%data;
}
```

[Run](https://demo.webdyne.org/release4/BoB) (user Bob)

[Run](https://demo.webdyne.org/release4/Alice) (user Alice)

------

### CGI Mode

The original WebDyne made use of Lincoln Stein's CGI.pm. That is long obsoleted and this version does not use it - but some of the CGI.pm tags have been preserved and re-implemented. Here's a quick and dirty "Choose your country" form:

```html
<start_html title="Choose Country">
<form>
Your Country ?
<popup_menu values="!{! &countries() !}"  default="Australia">
</form>

__PERL__
use Locale::Country;
sub countries {
    my @countries = sort { $a cmp $b } all_country_names();
    return \@countries;
}
```

[Run](https://demo.webdyne.org/release5.psp)

---

### Docker

Docker images are available and can be used for base containers for self-contained applications. See simple [Perl Fortune app](https://github.com/aspeer/psp-WebDyne-Fortune) as an example.

---

### Runtime Wrappers

WebDyne includes wrapper scripts for the main supported runtime modes:

```bash
# PSGI/Plack
webdyne.psgi --test
webdyne.psgi /path/to/site-root

# PAGI
webdyne.pagi --test
webdyne.pagi /path/to/site-root

# Temporary local Apache/mod_perl
webdyne.apache --test
webdyne.apache /path/to/site-root
```

The PAGI wrapper supports normal HTTP requests plus PAGI-specific server-sent event, WebSocket, and lifespan flows.

---

### Install

```bash
# Install from CPAN, bare module
#
cpanm WebDyne

# Install everything needed to get started with Plack/PSGI
#
cpanm Task::WebDyne::Plack
```

For PAGI, install the PAGI runtime stack needed by `webdyne.pagi`. For Apache/mod_perl, use `wdapacheinit` for permanent configuration or `webdyne.apache --test` for a temporary local server.

Docs: https://webdyne.org  
CPAN: https://metacpan.org/dist/WebDyne  

---

Feedback and technical discussion welcome.
