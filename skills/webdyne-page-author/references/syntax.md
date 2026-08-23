# WebDyne PSP Syntax

## Page Parsing And Lifecycle

A PSP file is HTML parsed into a WebDyne tree, compiled into Perl callbacks, cached in process, and rendered for each request. The source mtime invalidates compiled page data.

- The parser is HTML-aware, so malformed markup can be repaired or rearranged like normal HTML parser input. Validate the rendered DOM, not just the source.
- Lines beginning with `#` before the first valid tag are source comments and are discarded. Later `#` text is page content.
- `<end_html>` is optional for compact pages because dangling document tags close at EOF.
- `__PERL__` or `__CODE__` begins the raw Perl tail. Do not put HTML after it.
- Top-level statements in the raw tail initialize the compiled page package. Request work belongs in handlers.
- Each source page gets a unique generated package, so page-local handler names do not collide with handlers in another PSP file.

Minimal full page:

```html
<start_html title="Server Time" h1>
<p>The local server time is <? scalar localtime() ?></p>
```

Explicit HTML remains valid when a project needs exact document structure:

```html
<!doctype html>
<html lang="en">
<head><title>Example</title></head>
<body><p>Hello</p></body>
</html>
```

## Perl Forms

Use the smallest suitable form:

```html
<!-- Processing instruction -->
<p><? scalar localtime() ?></p>

<!-- Inline perl element -->
<p><perl>(localtime())[5] + 1900</perl></p>

<!-- Inline substitution -->
<p>!{! uc('hello') !}</p>

<!-- Named handler and markup template -->
<perl handler="greeting">
<p>${name}</p>
</perl>

__PERL__

sub greeting {
    my $self=shift();
    return $self->render(name => ($_{"name"} || "Anonymous"));
}
```

`<script type="application/perl">...</script>` is a compatibility form for inline Perl. Native `<perl>` or processing-instruction syntax is clearer for new pages.

HTML data aliases such as `<div data-webdyne-perl="...">` exist for editor compatibility. Prefer native WebDyne elements unless the surrounding project uses those aliases.

### Arguments And Lexical Scope

Inline code is compiled as a callback and receives:

- `$_[0]`: the current WebDyne page object, normally named `$self`.
- `$_[1]`: the current tag parameter or inherited render-parameter hash.

A called helper does not inherit the callback arguments automatically:

```html
<!-- helper() gets no arguments -->
<? helper() ?>

<!-- Forward the WebDyne callback arguments -->
<? helper(@_) ?>
```

Lexicals in the raw tail are not visible to separately compiled inline chunks. This is fragile:

```html
<p><? $label ?></p>

__PERL__
my $label="not in the inline callback's lexical scope";
```

Use a helper, a handler, or render data instead:

```html
<perl handler="label"><p>${label}</p></perl>

__PERL__

sub label {
    my $self=shift();
    return $self->render(label => "visible");
}
```

## Handler Elements

Prefer `handler`; `method` is a compatibility alias:

```html
<perl handler="account">...</perl>
<perl handler="MyApp::Page::account"/>
```

`<perl handler/>` is shorthand for `<perl handler="handler"/>`.

Common attributes:

| Attribute | Meaning |
| --- | --- |
| `handler`, `method` | Call a page-local or fully qualified subroutine. |
| `package` | Package used with the handler name. |
| `require` | Load a module, or a file resolved relative to the page directory. |
| `import` | Alias named functions from the required package. This is not a call to the module's custom `import()`. |
| `param` | Pass a scalar or hash ref as the handler's second argument. |
| `run` | Run only for a true value. |
| `static` | Evaluate while compiling and retain the result. |
| `file` | Evaluate Perl loaded from a file. |
| `hidden`, `display=0` | Execute but suppress output. |
| `chomp` | Remove trailing newlines. |
| `autonewline` | Add line endings to queued print output. |

A fully qualified handler normally causes WebDyne to require the module portion. For complex module loading/import behavior, use ordinary `use` statements in the raw Perl tail.

### Handler Output Contract

Markup enclosed by a handler element is a template; it is not emitted automatically.

Supported normal handler results:

- Scalar ref: rendered directly and preferred for generated output.
- String: accepted and converted into renderable output.
- Hash ref: used as parameters for an implicit `$self->render(...)`.
- Array ref: supported for multiple output pieces.
- `\undef`: successful, intentional no output.

Explicit template rendering is easiest to read:

```html
<perl handler="summary">
<p>${count} records</p>
</perl>

__PERL__

sub summary {
    my $self=shift();
    return $self->render(count => 12);
}
```

Equivalent hash-ref return:

```perl
sub summary {
    return {count => 12};
}
```

For programmatic HTML:

```perl
sub badge {
    my $self=shift();
    my $html_or=$self->html_tiny();
    my $html=$html_or->span({class => "badge"}, "Ready");
    return \$html;
}
```

Use `$self->print`, `printf`, or `say` only when queued imperative output is clearer than a template.

## Substitutions

| Form | Source | Typical use |
| --- | --- | --- |
| `${name}` | Current render parameters | Handler templates and blocks |
| `+{name}` | CGI/request parameters | Simple submitted/query values |
| `*{NAME}` | Environment | Runtime values |
| `^{method}` | Request adapter method | Backend-supported request metadata |
| `!{! perl !}` | Evaluated Perl | Short computed values |
| `@{ perl }` | Evaluated array ref/list | Whole structured attribute values |
| `%{ perl }` | Evaluated hash ref | Whole structured attribute values |

Examples:

```html
<p>Hello +{name}</p>
<p>Request took ${elapsed} seconds</p>
<span class="state-!{! current_state(@_) !}">...</span>

<popup_menu
  name="color"
  values="@{qw(red green blue)}"
  labels="%{red => 'Red', green => 'Green', blue => 'Blue'}">
```

`${name}` is strict by default: a missing render value is an error. Pass every value used by the handler template.

Use the scalar-ref recovery convention when a method intentionally returns a scalar ref:

```perl
my $perl_sr=$self->cache_mtime();
my $mtime=${$perl_sr};
```

### Attributes Are Single Parser Values

Do not nest a WebDyne tag inside an attribute:

```html
<!-- Wrong -->
<progress value="<perl handler="pct"/>" max="100"></progress>
```

Evaluate a short value:

```html
<progress value="!{! pct(@_) !}" max="100"></progress>
```

Or render the attribute from a surrounding handler template:

```html
<perl handler="progress">
<progress value="${pct}" max="100"></progress>
</perl>

__PERL__

sub progress {
    my $self=shift();
    return $self->render(pct => 75);
}
```

Keep `@{...}` and `%{...}` as the complete dynamic attribute value. They return structured Perl data for WebDyne helpers; they are not string interpolation syntax.

WebDyne normalizes rendered HTML attributes to double quotes. Do not depend on source single quotes surviving, especially for JSON-like frontend attributes.

## Request And Render Parameters

`$self->CGI()` returns the current CGI::Simple-compatible wrapper.

```perl
my $cgi_or=$self->CGI();
my $name=scalar($cgi_or->param("name"));
my @features=$cgi_or->param("features");
my $vars_hr=$cgi_or->Vars();
```

During normal synchronous page evaluation, WebDyne dynamically aliases `%_` to `$self->CGI()->Vars()`:

```perl
my $name=$_{"name"};
```

Rules:

- `%_` is a shortcut for request CGI values, not the second handler argument.
- Scalar `%_` values reflect the last value of repeated input.
- Use `param()` in list context or `Vars()->get_all($name)` for multivalue fields.
- Use explicit arguments in async SSE/WebSocket handlers.
- A `param=%{...}` attribute supplies handler/tag parameters as `$_[1]`; it does not replace CGI input.

Render parameters are inherited through nested handler templates and blocks. Explicit child values override inherited values.

## Core Elements

| Element | Purpose |
| --- | --- |
| `<start_html>`, `<end_html>` | Generate the document shell and resources. |
| `<perl>` | Evaluate inline code or a named handler. |
| `<block>` | Define reusable/delayed markup for `render_block`. |
| `<include>` | Include files or extracted head/body/block content. |
| `<json>` | Serialize Perl data into an application/json script element. |
| `<api>` | Route a JSON endpoint. |
| `<htmx>` | Select and return an HTML fragment. |
| `<dump>` | Emit diagnostics when enabled/forced. |
| `<subst>` | Control substitution behavior for enclosed content. |

## start_html

Frequently useful attributes:

| Group | Attributes |
| --- | --- |
| Document | `title`, `meta`, `base`, `target`, `author` |
| Generated heading | `h1` through `h6`, optional `hr` |
| Styles | `style`, `style_prepend`, `style_append`, `include_style` |
| Scripts | `script`, `script_prepend`, `script_append`, `include_script` |
| Other include | `include` |
| Lifecycle | `static`, `cache`, `handler` |
| PAGI | `sse`, `ws` |
| Configured shortcuts | `pico`, `htmx`, `alpine` |

`style` and `script` replace configured defaults. Use prepend/append variants to extend configured lists.

```html
<start_html
  title="Dashboard"
  h2
  hr
  style_append="dashboard.css"
  htmx>
```

A script URL fragment can supply script attributes:

```html
<start_html script="app.js#defer&integrity=sha384-...">
```

Unknown, non-control attributes pass through to the generated `<html>` element.

## Page Object Methods

Common methods available to handlers:

| Method | Use |
| --- | --- |
| `CGI()` | Current request parameters and uploads. |
| `r()`, `request()` | Current runtime request adapter. |
| `html_tiny()` | Request-aware WebDyne::HTML::Tiny generator. |
| `render(...)` | Render the current handler template. |
| `render_block(name, ...)` | Schedule/render named block markup. |
| `render_reset()` | Discard currently accumulated handler rendering. |
| `include(...)` | Programmatic equivalent of `<include>`. |
| `redirect(uri => ...)` | Redirect to a URI. |
| `redirect(html|json|text => \$data)` | Replace prior output with typed content. |
| `filename()`, `cwd()` | Main source filename and page working directory. |
| `inode(@seed)` | Page UID or cache variant UID. |
| `source_mtime()`, `cache_mtime()` | Source/cache timestamps. |
| `cache_compile([bool])` | Read or force cache recompilation state. |
| `meta()` | Process-persistent page metadata. |
| `no_cache()` | Set browser/proxy no-cache headers. |
| `render_time()` | Elapsed request rendering time. |
| `err(message)` | Raise a WebDyne error. |

Changes made through `meta()` persist for that compiled page in the current process. Do not store request-specific state there.

## Escaping And Trust

WebDyne can be configured with automatic CGI escaping disabled, and the render path deliberately preserves values in that mode. Treat substitutions as rendering mechanics, not an XSS boundary:

- Validate identifiers, route pieces, filenames, and cache seeds.
- Escape untrusted text before returning programmatic HTML.
- Prefer structured HTML generation with `$self->html_tiny()` over hand-built tags.
- Never interpolate untrusted data into Perl code or module/file names.
