# NAME

wdtidy - conservatively indent WebDyne PSP source using libtidy

# SYNOPSIS

```sh
wdtidy page.psp > page.tidy.psp
wdtidy --indent 2 --outfile page.tidy.psp page.psp
wdtidy --tidy /opt/homebrew/bin/tidy < page.psp
```

# DESCRIPTION

Requires the HTML Tidy executable (`tidy`, backed by libtidy), plus WebDyne's
existing Perl dependencies. All implementation is in `bin/wdtidy`; there is no
new Perl module. Input and output default to standard input and standard output.
`--outfile` is opened only after formatting succeeds. The input file is not
changed unless explicitly selected as the output file.

Tidy receives a synthetic XML outline containing numbered source markers.
Its indentation is applied to existing whitespace between PSP tags. Original
tags, attributes, entities, text, comments and processing instructions are
retained verbatim. Tidy cannot repair, drop, reorder or wrap PSP markup because
it never receives that markup. The returned marker sequence is checked before
any output is written. This also supports fragments, unknown tags and incomplete
HTML without imposing Tidy's HTML document structure.

Raw `__PERL__` and `__CODE__` tails, inline Perl elements, `<? ... ?>`, `!{! ... !}`,
Perl attributes, and `api`, `json` and `htmx` elements with a `perl` attribute are
preserved. Script, style, preformatted text, textarea, SVG, MathML and elements
with `data-webdyne-*` attributes are also preserved as complete regions.
Markup inside named Perl handlers can be indented. Unterminated or ambiguous
regions are retained rather than repaired. No page code is executed by wdtidy.

The default indentation is four spaces; `--indent` accepts 1 through 16.
Existing CRLF line endings are respected. Existing single-line tags stay on one
line, and existing multiline attributes are left as supplied, including any
embedded Perl. Section breaks retain up to one blank line.

# LIMITATIONS

This is an indentation tool, not an HTML repair tool. It changes only existing
whitespace between tags and never inserts whitespace where there was none.
Consequently, completely compact markup can remain unchanged. Text and inline
adjacency are preserved. Nesting is estimated from explicit closing tags;
implicitly closed HTML and WebDyne helpers can receive less detailed indentation.

As with any source formatter, source line numbers change. Pages inspecting their
own source or Perl `__LINE__`, or scripts/CSS depending on exact inter-element
whitespace, can observe those changes. Preserving arbitrary runtime behavior
cannot be guaranteed by a formatter. Whitespace-sensitive element bodies are
left untouched, and representative pages are covered by render comparisons.

Missing/failed Tidy or a changed marker sequence causes a nonzero exit without
writing output. `--help` prints a brief usage message.
