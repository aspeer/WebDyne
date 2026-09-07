# Architecture decisions

## Portable PAGI lifespan callbacks (2026-09-07)

WebDyne owns callback invocation and protocol acknowledgements. The constructor
accepts coderefs, keeping module discovery and string configuration in launchers.
The public lifespan_callback method centralizes synchronous/Future execution
and lets launchers detect callback support before loading an older embedded
WebDyne that would otherwise silently ignore the constructor options.
