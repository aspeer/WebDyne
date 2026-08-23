# WebDyne Validation And Debugging

No single tool validates every layer. Check Perl syntax, WebDyne compilation, rendered output, and runtime-specific behavior separately.

## Use Development Libraries Correctly

For an installed release:

```bash
wdlint page.psp
wdrender page.psp
```

Inside the WebDyne repository when the development modules are not installed:

```bash
perl -Ilib bin/wdlint page.psp
perl -Ilib bin/wdrender page.psp
perl -Ilib bin/wdcompile page.psp
```

`-Ilib` belongs on these commands, not in PSP source or production launcher configuration.

## wdlint

`wdlint` compiles to WebDyne stage 0, extracts Perl, and invokes `perl -c -w` with `use strict`.

Current coverage includes:

- Raw page code after `__PERL__` or `__CODE__`.
- Inline `<perl>...</perl>` code.
- Processing instructions such as `<? ... ?>`.
- `!{! ... !}` substitutions in text and attributes.
- Whole attribute expressions using `@{...}`, `%{...}`, and `!{!...!}`.

It deliberately does not lint non-Perl substitutions such as `${render_name}` or `+{cgi_name}`.

Page code is checked first. Each inline fragment is then checked separately, so a syntax error in a `<? ... ?>` block does not hide an independent error in a later `!{! ... !}` fragment.

```bash
perl -Ilib bin/wdlint page.psp
perl -Ilib bin/wdlint -Iapp/lib page.psp
```

Arguments before the final source filename are passed to Perl. Put the PSP filename last.

Limits:

- This is Perl syntax checking, not WebDyne runtime execution.
- It does not validate HTML nesting, handler existence, return types, render parameters, includes, routes, or async lifecycle.
- Separately compiled inline chunks cannot always reproduce every runtime lexical/package interaction. Prefer handlers when a fragment depends on page-level code.
- A page-level syntax error can make helper declarations unavailable while chunks are checked; fix foundational page errors before interpreting follow-on diagnostics.

## wdrender

Render the page to exercise parsing, compilation, handlers, substitutions, and output:

```bash
perl -Ilib bin/wdrender page.psp
perl -Ilib bin/wdrender --raw page.psp
perl -Ilib bin/wdrender --header page.psp
```

Use representative input:

```bash
perl -Ilib bin/wdrender --get name=Alice page.psp
perl -Ilib bin/wdrender --post 'name=Alice&features=docs&features=speed' page.psp
```

Test an HX request:

```bash
perl -Ilib bin/wdrender --htmx fragment.psp
perl -Ilib bin/wdrender --raw --headers_in=hx-request:true fragment.psp
```

Useful diagnosis:

```bash
perl -Ilib bin/wdrender --repeat=2 --compare page.psp
perl -Ilib bin/wdrender --request=all page.psp
```

`wdrender` confirms WebDyne output for simulated requests. It does not confirm browser DOM behavior, JavaScript execution, proxy behavior, or a persistent PAGI connection.

## wdcompile

Use `wdcompile` when the parser/tree or optimizer is suspect:

```bash
perl -Ilib bin/wdcompile --stage0 page.psp
perl -Ilib bin/wdcompile --stage3 page.psp
perl -Ilib bin/wdcompile --final page.psp
perl -Ilib bin/wdcompile --all page.psp
```

Early stages show the less-optimized parsed tree. Later stages show what remains dynamic. Compare them when:

- An HTML element closes or moves unexpectedly.
- A WebDyne tag disappears.
- Static compaction changes output.
- An attribute expression is attached to the wrong node.
- Raw Perl appears to have entered the HTML tree.

Use `--meta` to inspect page metadata such as raw Perl, static/cache flags, or PAGI handler declarations.

## Debug Logging

Enable comprehensive WebDyne debugging:

```bash
WEBDYNE_DEBUG=1 perl -Ilib bin/wdrender --raw page.psp
```

Narrow output where supported:

```bash
WEBDYNE_DEBUG=WebDyne::Compile \
WEBDYNE_DEBUG_FILTER='perl|tree|line' \
perl -Ilib bin/wdrender --raw page.psp
```

Capture enough context to identify the compile stage and source line. Do not leave debug output enabled in production or committed examples.

## Repository Tests

Run the narrowest test first:

```bash
prove -Ilib t/05-htmx.t
prove -Ilib t/26-bin-wdlint.t
prove -Ilib t/34-pagi-sse.t t/35-pagi-websocket.t
```

Then broaden according to impact:

```bash
prove -Ilib t
make test
```

Use `-Ilib` explicitly for development proofing unless the build/test harness already inserts the repository library.

Generated render fixtures can include harmless final whitespace differences, but actual HTML/tree differences require explanation. Do not rebuild expected artifacts merely to conceal a behavioral regression.

## Validation By Page Type

### Full Page

- Lint all Perl.
- Render normal and representative parameterized requests.
- Check title/head resources and body output.
- Validate final HTML structure with an HTML/DOM tool or browser.

### Form

- Test initial render and submitted render.
- Test empty, invalid, and repeated values.
- Check state persistence and `force` behavior.
- For uploads, test multipart parsing, duplicate fields, limits, and filename validation.

### Include/Template

- Render from the actual working/document root.
- Verify relative paths, extracted head/body/block content, and supplied params.
- Check `nocache` only where runtime freshness requires it.

### Static/Cache

- Render repeatedly and compare.
- Change source and confirm invalidation.
- Exercise cache expiry/recompile conditions.
- Verify variant completeness and bounded keys.
- Test across multiple workers when shared behavior matters.

### JSON/API

- Parse output as JSON rather than visually inspecting it.
- Verify status and content type.
- Test matched, invalid, and unmatched routes.
- Distinguish route matches from CGI parameters.
- Restart workers when testing newly added API file paths.

### HTMX

- Render normal request behavior.
- Render with an HX request header.
- Verify exactly one selected fragment and no unwanted document shell.
- Check target/swap semantics in a browser.
- Avoid quote-fragile raw JSON in attributes.

### SSE/WebSocket

- Lint and render the ordinary HTTP page first.
- Run PAGI integration tests or a PAGI server.
- Verify connection parameters, handshake/start headers, messages/events, disconnects, terminal close, and producer cleanup.
- For SSE, confirm the browser does not reconnect after terminal completion.

## Common Failure Diagnosis

| Symptom | Likely check |
| --- | --- |
| Inline helper sees undefined `$self` | Pass `@_` or use a named handler. |
| Closing tags move/disappear | Inspect stage 0 tree and validate source HTML nesting. |
| Dynamic attribute breaks parsing | Replace nested tags with `!{! ... !}` or surrounding handler render params. |
| Missing `${name}` failure | Supply every strict render parameter. |
| Only first selected value appears | Use CGI list context or `get_all` instead of `%_`. |
| HTMX returns nothing in direct render | Supply HX header/`--htmx` or temporary `force`. |
| HTMX returns a full page | Confirm the request header and fragment/bare structure. |
| SSE page never updates | Run under PAGI and inspect stream handler/start/event names. |
| SSE reconnects after completion | Send terminal event, configure client `sse-close`, and close server stream. |
| Async handler loses query values | Use its explicit `$param_hr` argument across `await`. |
| Correct source uses stale API route | Restart workers to clear route filename discovery cache. |
| Cache returns another user's state | Remove caching or include all validated response inputs in a bounded variant. |

## Temporary Probes

When behavior remains ambiguous, create the smallest disposable PSP that isolates one parser or runtime feature. Run lint, compile stages, and raw render against it. Keep the probe out of release manifests and remove it after the behavior is understood unless it becomes a focused regression test.
