---
name: webdyne-page-author
description: Use when creating, editing, reviewing, or explaining WebDyne .psp pages and WebDyne page syntax, including start_html, perl tags, __PERL__, blocks, includes, form helper tags, substitutions, JSON/API/HTMX tags, sessions, static pages, PSGI/PAGI/Apache runtime assumptions, and validation with wdrender or wdlint.
---

# WebDyne Page Author

Use this skill to produce correct WebDyne PSP source for application pages, examples, includes, fragments, and small server-rendered tools. Prefer WebDyne-native syntax over generic templating conventions.

## Workflow

1. Identify the target file type: full `.psp` page, include, htmx fragment, API-only route page, example, or module-backed app page.
2. For full pages, start with `<start_html>` unless the surrounding project already uses explicit `<html><head><body>` markup.
3. Keep page HTML readable. Move larger Perl logic into `__PERL__` handlers or external modules instead of embedding long inline code.
4. Use WebDyne form helper tags for normal forms unless the project already uses raw HTML form controls.
5. Use `+{param}` or `${name}` substitutions in markup and `$self->render(...)` / `$self->render_block(...)` from handlers.
6. If a request needs JSON data, API routing, htmx fragments, sessions, or static rendering, read the matching reference below before writing code.
7. When editing an existing project, follow its local `.psp` style and runtime assumptions.

## Reference Routing

Read only the references needed for the task:

- `references/syntax.md`: core PSP syntax, substitutions, tags, handler conventions, and methods.
- `references/patterns.md`: common page patterns for forms, blocks, includes, JSON, API routes, htmx, sessions, and static pages.
- `references/runtime.md`: deployment/runtime assumptions for standalone rendering, PSGI/PAGI/Apache, Docker, config, and environment variables.
- `references/validation.md`: commands for checking/rendering `.psp` pages and troubleshooting generated code.

## Authoring Rules

- Prefer `handler` in new examples. Treat `method` as a compatibility alias.
- Use `<perl handler/>` only when the handler routine is named `handler`.
- Remember handler-style WebDyne calls receive `$self` as the first argument. Processing instructions like `<? func() ?>` do not automatically pass `$self`; pass `@_` or use `<perl handler="func"/>` when the handler needs the page object.
- Prefer returning scalar refs for larger generated strings, but returning strings or using `$self->render()` is acceptable in page examples.
- Return `\undef` from a handler when it should render nothing.
- Do not invent WebDyne tags or frontend shortcuts beyond the documented ones.
- Generated pages should be valid HTML after WebDyne renders them.

## Output Expectations

When creating a page, provide the `.psp` source and any required companion files or runtime assumptions. When reviewing or editing a page, explain WebDyne-specific issues plainly and point to the smallest correction.
