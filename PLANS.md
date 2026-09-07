# PAGI request diagnostics

Clear shared diagnostics at synchronous HTTP, SSE and WebSocket setup, after
any body buffering. Preserve current-request error handling and avoid adding
an application wrapper or changing nested core handler calls.

Implemented and validated on 2026-09-07:

- The new test reproduced cross-request failures before the fix and passes
  all 28 assertions afterward, including interleaved HTTP/SSE body reads.
- `prove -lr t`: 73 files, 3,904 assertions pass. Three Apache-specific files
  skip because Apache/mod_perl dependencies are unavailable.
- The same 28 assertions pass with local ZeroPerl 5.44.0 build 8 and the
  development WebDyne library overlaid into its virtual filesystem. The WASM
  harness supplies Test::More/Test2, captures TAP through scalar handles, and
  substitutes a host-created directory for File::Temp's unsupported mkdir.
  No application-entry reset is loaded. This is a local WASM check, not a
  deployed Cloudflare acceptance run.

The WASM bootstrap reset remains until a runtime bundles the updated core.


# PAGI lifespan callbacks (2026-09-07)

Add optional startup/shutdown coderefs to the portable PAGI constructor.
Callbacks receive the application and lifespan scope; returned Futures are
awaited before acknowledgement. Callback errors send the matching failure
event and end the lifespan session. Transport errors propagate unchanged.

Implement and verify on development, then merge into main as requested before
adding callback-name configuration to the ZeroPerl scaffold. No shutdown host
dispatch, shared state or Cloudflare capability changes are part of this step.

Validated: `prove -lr t` passes 74 files and 3,949 assertions; Apache-specific
tests skip where their dependencies are unavailable. All 45 callback assertions
also pass in Perl 5.44 WASM build 8 with the development WebDyne library overlaid.
The maintained PAGI.pm.md sidecar is updated; the configured docbook-convert
command is unavailable locally, so generated embedded POD awaits regeneration.
