# Lifespan callback verification

`t/pagi-lifespan-callbacks.t` covers constructor validation, absent callbacks,
callback arguments, false normal returns, pending startup and shutdown Futures,
exceptions and failed Futures in both phases, session completion, and transport
send failure without a second response. Run with `prove -lv`.

Validated: `prove -lr t` passes 74 files and 3,949 assertions; Apache-specific
tests skip where their dependencies are unavailable. All 45 callback assertions
also pass in Perl 5.44 WASM build 8 with the development WebDyne library overlaid.
The maintained PAGI.pm.md sidecar is updated; the configured docbook-convert
command is unavailable locally, so generated embedded POD awaits regeneration.
