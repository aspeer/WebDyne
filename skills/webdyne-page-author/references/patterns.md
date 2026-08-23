# WebDyne Rendering Patterns

## Keep HTML In The Page

For substantial output, make PSP markup the template and keep the handler focused on data:

```html
<start_html title="Account" h1>

<perl handler="account">
<dl>
  <dt>Name</dt>
  <dd>${name}</dd>
  <dt>Plan</dt>
  <dd>${plan}</dd>
</dl>
</perl>

__PERL__

sub account {
    my $self=shift();
    my $account_hr=load_account();

    return $self->render(
        name => $account_hr->{"name"},
        plan => $account_hr->{"plan"},
    );
}
```

For a tiny programmatic element, use the page HTML generator:

```perl
sub status_badge {
    my $self=shift();
    my $html_or=$self->html_tiny();
    my $html=$html_or->span({class => "status"}, "Ready");
    return \$html;
}
```

Do not create local `tag()` or `h()` helpers when `$self->html_tiny()` already provides structured HTML generation.

## Conditional And Repeated Blocks

A `<block>` is hidden until selected. Use it to avoid assembling markup in Perl.

```html
<perl handler="check">
<block name="pass">
  <p class="success">Correct: +{sum}</p>
</block>
<block name="fail">
  <p class="error">+{sum} is not correct.</p>
</block>
</perl>

__PERL__

sub check {
    my $self=shift();
    return \undef unless length($_{"sum"} || "");

    $self->render_block(($_{"sum"} == 4) ? "pass" : "fail");
    return $self->render();
}
```

Pass render data to a block:

```html
<perl handler="rows">
<ul>
  <block name="row"><li>${name}: ${count}</li></block>
</ul>
</perl>

__PERL__

sub rows {
    my $self=shift();

    for my $row_hr (@{load_rows()}) {
        $self->render_block("row", %{$row_hr});
    }

    return $self->render();
}
```

Important behavior:

- Calling `render_block` repeatedly repeats every matching named block.
- A block inside the active handler template is published by the subsequent `return $self->render()`.
- A block appearing later/outside the handler can be scheduled before WebDyne reaches it.
- Multiple blocks can share a name.
- `display` makes a block render normally without prior registration.
- `static` makes a block compile-time output.

## Forms

WebDyne form helpers are request-aware and normally preserve submitted values.

```html
<start_html title="Survey" h1>

<start_form>
<textfield name="name" label="Name">
<popup_menu
  name="color"
  values="@{qw(red green blue)}"
  labels="%{red => 'Red', green => 'Green', blue => 'Blue'}"
  label="Favorite color">
<checkbox_group
  name="features"
  values="@{qw(speed docs examples)}"
  defaults="@{qw(docs)}">
<submit value="Submit">
<end_form>

<perl handler="summary">
<p>Name: ${name}</p>
<p>Color: ${color}</p>
<p>Features: ${features}</p>
</perl>

__PERL__

sub summary {
    my $self=shift();
    my $cgi_or=$self->CGI();
    return \undef unless $cgi_or->param();

    my @features=$cgi_or->param("features");
    return $self->render(
        name     => scalar($cgi_or->param("name")) || "",
        color    => scalar($cgi_or->param("color")) || "",
        features => join(", ", @features),
    );
}
```

Form helper families:

- Form boundaries: `<start_form>`, `<start_multipart_form>`, `<end_form>`.
- Text/input: `<textfield>`, `<password_field>`, `<textarea>`, `<filefield>`, `<hidden>`.
- Selection: `<popup_menu>`, `<scrolling_list>`, `<checkbox>`, `<checkbox_group>`, `<radio_group>`.
- Commands: `<button>`, `<submit>`, `<reset>`, `<image_button>`, `<defaults>`.

`<start_form>` defaults to POST. `<start_multipart_form>` defaults to POST with `multipart/form-data`.

Selection helpers commonly accept:

- `values`: array ref or hash ref.
- `labels`: value-to-label hash ref.
- `attributes`: per-value attribute hash.
- `default`, `defaults`, `selected`, or `checked`.
- `disabled`, `multiple`, `linebreak`, and `force` where applicable.

Prefer an ordered values array plus labels hash when order matters. Perl hash key order is not presentation order.

Use `force` when the declared default must override the request-persisted value.

### Checkbox And Repeated Values

A simple WebDyne checkbox can emit a hidden field as well as the checkbox so unchecked state survives submission. Scalar access returns the effective last value; list access can expose every submitted value.

```perl
my $enabled=scalar($self->CGI()->param("enabled"));
my @selected=$self->CGI()->param("features");
my @selected_again=$self->CGI()->Vars()->get_all("features");
```

Do not use `$_{"features"}` when the application needs all selected values.

### Uploads

Use a multipart form and retrieve uploads through the CGI wrapper:

```html
<start_multipart_form>
<filefield name="attachment" label="Attachment">
<submit value="Upload">
<end_form>
```

```perl
my $uploads_hr=$self->CGI()->uploads();
my @uploads=$uploads_hr->get_all("attachment");

for my $upload_or (@uploads) {
    my $name=$upload_or->filename();
    my $size=$upload_or->size();
    my $fh=$upload_or->fh();
}
```

Upload objects also provide values such as basename, content type, path, and content. Validate filenames, media types, sizes, and destination paths before storing data.

## Includes

Includes resolve relative paths from the containing page directory.

```html
<include file="./nav.html">
<include head file="./layout.psp">
<include body file="./layout.psp">
<include block="footer" file="./layout.psp">
<include file="./notes.txt" wrap="pre">
```

Use `param` for included PSP render data:

```html
<include file="./card.psp" param="%{title => 'Current status'}">
```

The `file` value can be an array ref. The same behavior is available through `$self->include(...)`.

By default, included content participates in compiled/cached page data. `nocache` reparses the include for every request; reserve it for files whose contents genuinely change independently of the page source.

Included PSP content runs in the current page rendering context. Keep included fragments free of accidental global/page initialization assumptions.

## Static Rendering

Static output is evaluated at compile time and reused in the process:

```html
<start_html static title="Build Information">
<p>Compiled at <? scalar localtime() ?></p>
```

Alternatives include a WebDyne meta directive, `static` on supported elements/blocks, or:

```html
__PERL__
use WebDyne::Static;
```

Only use static rendering for output independent of request parameters, identity, session, time-sensitive data, and mutable backend state.

## Disk Cache

WebDyne cache pages are static renderings whose cache callback decides whether to compile/rebuild.

```html
<start_html title="Report" cache="&cache">
<p>Generated report content...</p>

__PERL__

sub cache {
    my $self=shift();
    my $perl_sr=$self->cache_mtime();
    my $cache_mtime=${$perl_sr} || 0;

    $self->cache_compile(1)
        if time() - $cache_mtime > 300;

    return 1;
}
```

Module form:

```perl
use WebDyne::Cache (\&cache);
```

Cache notes:

- Disk cache requires a configured `WEBDYNE_CACHE_DN`.
- `cache_mtime()` returns a scalar ref; recover it with `${$perl_sr}`.
- `cache_compile(1)` requests regeneration.
- `inode($seed)` selects a cache variant.
- Cache implies static page behavior.
- Validate and bound every variant seed. Raw user input can otherwise create an unlimited number of cache files.
- Include every input that changes the response in the cache variant, or do not cache that page.

Example bounded variant:

```perl
sub cache {
    my $self=shift();
    my $month=$_{"month"} || "current";
    $month="current" unless $month=~/\A(?:current|20\d\d-(?:0[1-9]|1[0-2]))\z/;

    $self->inode($month);
    return 1;
}
```

## Sessions

Loading `WebDyne::Session` inserts session handling into the request chain and exposes `session_id()`:

```html
<start_html title="Session">
<p>Session ID: !{! shift()->session_id() !}</p>

__PERL__

use WebDyne::Session;
1;
```

Session behavior depends on the configured store, cookie name, expiry, and runtime. Avoid putting session-dependent output in static or shared cache pages.

## Templates

`WebDyne::Template` can wrap a content page with a template and extract/merge head and body content.

Content page shape:

```html
<start_html title="About">
<p>About page content.</p>

__PERL__

use WebDyne::Template qw(template.psp);
```

Use it when the existing deployment or application already adopts WebDyne templates. For a small standalone page, ordinary includes and blocks are easier to reason about.

WebDyne::Chain can apply Session, Template, Static, Cache, and related extensions by location/runtime configuration. A page running under a configured chain may inherit behavior that is not visible in its PSP source; inspect the runtime configuration before duplicating it in the page.

## External Application Modules

Keep thin PSP pages when business logic is shared:

```html
<start_html title="Orders">
<perl handler="MyApp::Page::orders">
  <block name="order"><li>${id}: ${status}</li></block>
</perl>
```

A fully qualified handler can load the matching module automatically. Use the page markup as the view contract and let the module render its template/blocks through the supplied `$self`.

## Failure And Empty States

Make empty output intentional:

```perl
return \undef unless $self->CGI()->param("submitted");
```

Raise actionable failures through WebDyne:

```perl
return $self->err("unable to load account") unless $account_hr;
```

Do not rely on a false scalar such as `0` to distinguish success from empty output. Use a scalar ref for output and `\undef` for successful silence.
