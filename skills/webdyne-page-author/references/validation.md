# WebDyne Validation

## Perl Syntax

Use `wdlint` to check the Perl section after `__PERL__`:

```bash
wdlint page.psp
wdlint -Ilib page.psp
```

`wdlint` injects `use strict;` and runs Perl syntax checking. It catches Perl syntax errors in the `__PERL__` section but does not validate HTML, WebDyne tag semantics, or runtime behavior.

## Render A Page

Use `wdrender` to compile and render:

```bash
wdrender page.psp
wdrender --raw page.psp
wdrender --header page.psp
```

Pass parameters:

```bash
wdrender --get name=Alice page.psp
wdrender --post 'name=Alice&color=red' page.psp
```

Render htmx fragments:

```bash
wdrender --htmx fragment.psp
```

Compare repeated renders:

```bash
wdrender --repeat=2 --compare page.psp
```

## Common Checks Before Finishing

- If the page uses `__PERL__`, run `wdlint` when available.
- If the page uses WebDyne tags or substitutions, render with `wdrender` when available.
- If using htmx, test both normal and `--htmx` rendering or include `force="+{debug}"` during debugging.
- If using forms, test with representative `--get` or `--post` parameters.
- If using JSON/API tags, confirm returned Perl data is a hash ref, array ref, scalar, or JSON boolean as appropriate.

## Common Mistakes

- Expecting `<? handler() ?>` to receive `$self`. Use `<perl handler="handler"/>` or pass `@_`.
- Using `method` in new examples. It works, but `handler` is preferred.
- Forgetting `return $self->render()` after rendering blocks inside a `<perl>` section.
- Returning plain `0` or `1` when JSON boolean semantics are required. Use `JSON::false` and `JSON::true`.
- Writing large inline Perl blocks when `__PERL__` handlers or external modules would be clearer.
