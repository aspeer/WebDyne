# Outstanding work

- Consider request/session-owned diagnostic storage if asynchronous callbacks
  need to retain WebDyne errors across suspension and resumption.
- Review caught-exception handling within a single render separately from
  resetting diagnostics between requests.
- Remove the WASM application's entry-point reset when its bundled WebDyne
  includes the synchronous request-boundary fix.

- Connect lifespan callback names in the ZeroPerl scaffold. Its host currently
  sends startup only; shutdown dispatch and shared lifespan state remain later
  increments.
- Regenerate embedded PAGI POD from its maintained Markdown sidecar when
  the configured docbook-convert tool is available.
