---
name: webdyne-page-author
description: Create, edit, review, explain, and validate WebDyne .psp pages and fragments. Use for WebDyne HTML/Perl syntax, start_html and form helpers, substitutions, handlers, blocks, includes, static/cache/session/template pages, JSON/API/HTMX endpoints, PAGI SSE/WebSockets, runtime selection, and wdlint/wdrender debugging.
---

# WebDyne Page Author

Produce WebDyne-native PSP source that is readable as HTML, keeps Perl in the right execution scope, and matches the target runtime. Apply this skill to full pages, includes, fragments, examples, and small module-backed applications.

## Establish Context

Before editing:

1. Inspect nearby `.psp` files, companion modules, configuration, and tests. Match their established style unless it conflicts with current WebDyne behavior.
2. Classify the output as a full page, included content, HTMX fragment, JSON data block, API route page, static/cache page, or PAGI stream/socket page.
3. Identify the runtime: direct/fake rendering, Apache, PSGI, or PAGI. SSE and WebSockets require PAGI.
4. Separate request input, render parameters, route matches, and async connection parameters. They are related but not interchangeable.
5. Decide whether HTML belongs in PSP markup, a reusable `<block>`, or programmatic `$self->html_tiny()` output. Prefer markup for substantial fragments.

## Authoring Standard

- Use `<start_html>` for a compact full page unless the project deliberately writes explicit document markup. Fragment and API pages need not use it.
- Keep short expressions inline. Put reusable or multi-step logic in named handlers below `__PERL__`, or in an application module when it is shared.
- Prefer `handler=` in new code. `method=` is a compatibility alias.
- Treat content inside `<perl handler="name">...</perl>` as a template: the handler must return output, return a hash ref for implicit rendering, or call `$self->render(...)`.
- Return scalar refs for generated HTML where practical. `$self->render()` already returns one. Use `\undef` for intentional empty output.
- Prefer `${name}` plus `$self->render(...)` for template data and `+{name}` for simple CGI request substitutions.
- Use `!{! ... !}` for short evaluated values, including dynamic HTML attributes.
- Never put a WebDyne element such as `<perl .../>` inside an HTML attribute. An attribute is one parser value, not a nested PSP tree.
- Use whole-value `@{...}` and `%{...}` expressions for array/hash attributes such as form values, labels, options, and parameters.
- `<start_html>` resource attributes accept arrays: use one ordered `script="@{qw(htmx.js extension.js)}"` (or equivalent array expression) for dependent libraries instead of `script_append` when no configured script list must be preserved. The same array form applies to `style`, `include_script`, and related resource attributes.
- For HTMX `hx-vals`, use the documented JavaScript form with a double-quoted HTML attribute, for example `hx-vals="js:{ action: 'advance' }"`. Do not use JSON inside a single-quoted attribute such as `hx-vals='{"action":"advance"}'`: WebDyne normalizes rendered attributes to double quotes, which can corrupt the embedded JSON.
- Use `$self->html_tiny()` when Perl genuinely needs to construct HTML. Do not add local escaping/tag-building helpers that duplicate it.
- Do not assume substitutions automatically make untrusted input safe. Escape or validate data at the application boundary.
- Keep expensive or request-dependent work out of top-level `__PERL__`: that section initializes the page package when compiled/loaded, not once per request.
- Keep cache keys bounded and validated. User-controlled cache seeds can otherwise create unbounded files.
- Produce valid rendered HTML. WebDyne parser acceptance alone is not an HTML correctness check.

## Parser And Scope Invariants

- `__PERL__` and `__CODE__` begin the raw Perl tail. HTML parsing stops there, so Perl operators containing `<`, `>`, or substitution syntax remain Perl.
- Every compiled page has its own generated package. Same-named page-local handlers do not collide across PSP files.
- Lexicals declared in the raw Perl tail are not visible to separately compiled inline chunks. Share behavior through handlers/helper subs or pass values through render parameters.
- Handler calls receive `$self` first. Inline chunks also receive inherited render/tag parameters as `$_[1]`.
- A processing instruction such as `<? helper() ?>` does not implicitly forward `@_` into `helper`. Use `<? helper(@_) ?>`, `<? helper(shift(), ...) ?>`, or a handler tag.
- During normal synchronous page evaluation, `%_` aliases the CGI `Vars()` hash and exposes the last value for a multivalue parameter. Use the CGI object for list-valued input.
- SSE and WebSocket handlers receive `($self, $param_hr)`. Use that explicit connection parameter hash across `await`; do not rely on dynamically localized `%_` in async code.
- API handlers receive `($self, $route_match_hr)`. That second argument contains route matches, not the CGI parameter hash.

## Reference Routing

Read only the references relevant to the current page:

- [Core syntax](references/syntax.md): parsing, page anatomy, Perl forms, substitutions, handler returns, attributes, core tags, and page methods.
- [Rendering patterns](references/patterns.md): handler templates, blocks, forms/uploads, includes, HTML::Tiny, static/cache, sessions, and templates.
- [Dynamic interfaces](references/interfaces.md): JSON, API, HTMX, PAGI SSE, WebSockets, and efficient event-driven update patterns.
- [Runtime](references/runtime.md): direct API use, Apache/PSGI/PAGI behavior, configuration, paths, dependencies, and deployment constraints.
- [Validation](references/validation.md): `wdlint`, `wdrender`, `wdcompile`, focused regression tests, debug output, and a page-type check matrix.

## Finish The Work

1. Run `wdlint` for all pages containing Perl. It checks page Perl and separately checks supported inline chunks.
2. Render representative normal and parameterized requests with `wdrender`.
3. For HTMX, test both the normal page and an HX request. For API, assert JSON and route behavior. For forms, exercise scalar and repeated values.
4. Run focused repository tests with `prove` when changing an existing project.
5. In a WebDyne source checkout whose development modules are not installed, invoke tools through Perl with `-Ilib`, for example `perl -Ilib bin/wdlint page.psp` and `perl -Ilib bin/wdrender page.psp`.
6. Use `WEBDYNE_DEBUG=1` for compiler/parser diagnosis, then remove temporary probes and debugging output.

When behavior is ambiguous, prefer the current repository implementation and tests over generated/manual sidecars that may lag development changes.
