# WebDyne PSP Syntax

## Minimal Page

Use `<start_html>` for compact full pages. WebDyne emits normal HTML with a generated head and body.

```html
<start_html title="Server Time" h1>
The local server time is: <? localtime() ?>
```

`<end_html>` exists but is usually optional because WebDyne closes dangling tags at EOF.

## Inline Perl

Use inline Perl sparingly for short values:

```html
The time is: <? localtime() ?>
Copyright (C) <perl>(localtime())[5] + 1900</perl>
```

The `!{! ... !}` form can be used in text and tag attributes:

```html
<span style="color: !{! (qw(red green blue))[rand 3] !}">Hello</span>
```

## Handler Perl

Use `<perl handler="name">...</perl>` with code in the `__PERL__` section for clearer pages:

```html
<start_html title="Greeting">
<perl handler="hello">
Hello ${name}, pleased to meet you.
</perl>

__PERL__

sub hello {
    my $self = shift;
    my $name = $_{'name'} || 'Anonymous';
    return $self->render(name => $name);
}
```

`<perl handler/>` is shorthand for `<perl handler="handler"/>`.

`method` is a compatibility alias for `handler`; prefer `handler` in new pages.

## Perl Tag Attributes

Common `<perl>` attributes:

- `handler=METHOD`: call a `__PERL__` subroutine or external fully qualified Perl function.
- `require=MODULE | FILE`: load a module or file.
- `import=FUNCTION | ARRAYREF`: import functions from a required module.
- `param=SCALAR | HASHREF`: pass parameters to the handler.
- `run=EXPR`: run only when the expression is true.
- `static`: run once and cache the output.
- `hidden` or `display=0`: run but suppress output.
- `chomp`: remove trailing newlines.
- `autonewline`: add newlines between prints.

Example:

```html
<perl require="POSIX" import="strftime">
strftime("%Y-%m-%d", localtime)
</perl>
```

## Substitutions

Use request parameter substitution in HTML:

```html
Hello +{name}
```

Use render-time substitution inside rendered templates and blocks:

```html
<perl handler="summary">
Total: ${total}
</perl>

__PERL__

sub summary {
    my $self = shift;
    return $self->render(total => 42);
}
```

## Page Object

Handler routines receive the WebDyne page object as first argument:

```perl
my $self = shift;
my $cgi  = $self->CGI();
```

Important methods:

- `CGI()`: current CGI::Simple-like request parameters.
- `request()` / `r()`: current request adapter.
- `render(%vars)`: render text inside the current `<perl>` tag with substitutions.
- `render_block($name, %vars)`: render named `<block>` content.
- `include(...)`: include content using `<include>` semantics.
- `redirect(uri => $uri)`, `redirect(html => \$html)`, `redirect(json => \$json)`, `redirect(text => \$text)`.
- `print`, `printf`, `say`: emit output into the current HTML stream.
- `err($message)`: raise a WebDyne error.

Processing instructions such as `<? server_time() ?>` do not automatically pass `$self`; call `<? server_time(@_) ?>` or use `<perl handler="server_time"/>` when the handler needs the page object.

## start_html

Useful attributes:

- `title=TEXT`
- `h1` through `h6`, optionally with `hr`
- `style=URL | ARRAYREF`
- `style_prepend=URL | ARRAYREF`, `style_append=URL | ARRAYREF`
- `script=URL | ARRAYREF`
- `script_prepend=URL | ARRAYREF`, `script_append=URL | ARRAYREF`
- `meta=HASHREF`
- `include`, `include_script`, `include_style`
- `static`
- `cache=METHOD`
- `handler=METHOD`
- `pico`, `htmx`, `alpine`
- `sse=METHOD`, `ws=METHOD` for PAGI

Examples:

```html
<start_html title="Dashboard" h1 pico htmx>
```

Use `style_prepend` / `style_append` or `script_prepend` / `script_append` when a page should add resources around configured `WEBDYNE_START_HTML_PARAM` resources. Use `style` or `script` when the page should replace the configured resource list.

```html
<start_html
  title="Chart"
  script="https://cdn.jsdelivr.net/npm/chart.js"
>
```

## Core Tags

- `<perl>`: run inline Perl or invoke a handler.
- `<json>`: encode a Perl hash/array/scalar as JSON inside a `<script type="application/json">`.
- `<api>`: route JSON API requests using Router::Simple patterns.
- `<htmx>`: serve HTML fragments for htmx-style requests.
- `<block>`: named HTML/PSP section rendered with `render_block`.
- `<include>`: include text, HTML, PSP, head/body, or named block content from another file.
- `<dump>`: diagnostic output when forced or debugging is enabled.

## Form Helper Tags

Use WebDyne form helpers for stateful form controls:

- `<start_form>` / `<end_form>`
- `<start_multipart_form>`
- `<textfield>`
- `<password_field>`
- `<textarea>`
- `<checkbox>`
- `<checkbox_group>`
- `<radio_group>`
- `<popup_menu>`
- `<scrolling_list>`
- `<filefield>`
- `<submit>`, `<reset>`, `<button>`, `<hidden>`

Most helpers pass standard HTML attributes through.

Checkbox note: `<checkbox>` emits a hidden field to retain state. `$_{'name'}` and `$self->CGI->param('name')` return the useful boolean/scalar value in typical scalar use, but array context can expose multiple values.
