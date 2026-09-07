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
