# WebDyne Dynamic Interfaces

## Choose The Smallest Interface

| Need | WebDyne facility |
| --- | --- |
| Embed server data for browser code | `<json>` |
| Return routed JSON only | `<api>` |
| Return an HTML fragment | `<htmx>` |
| Notify a browser of server changes | PAGI SSE |
| Bidirectional persistent messages | PAGI WebSocket |

Prefer ordinary request/response and HTMX fragments until a persistent connection is justified. SSE is appropriate for one-way notifications; WebSockets are appropriate when the client must also send messages over the same connection.

## JSON In A Page

`<json>` calls a handler, JSON-encodes its result, and emits a `<script type="application/json">` element:

```html
<start_html title="Chart">

<json id="chart-data" handler="chart_data"/>
<canvas id="chart"></canvas>

__PERL__

use JSON ();

sub chart_data {
    return {
        labels   => [qw(Jan Feb Mar)],
        datasets => [{
            label => "Sales",
            data  => [120, 150, 180],
        }],
        current => JSON::true,
    };
}
```

Use `JSON::true` and `JSON::false` for JSON booleans. Plain Perl `1` and `0` serialize as numbers.

Useful attributes:

- `handler` or `perl`: data producer.
- `id` and normal script attributes.
- `canonical`: deterministic key ordering.
- `pretty`: formatted output.

The handler may return a hash ref, array ref, scalar, scalar ref, or supported JSON boolean.

## API Route Pages

A page containing `<api>` is an API page: non-API tree content is discarded and the response is JSON.

```html
<api handler="order" pattern="/order/:id"/>

__PERL__

sub order {
    my ($self, $match_hr)=@_;

    return {
        id     => $match_hr->{"id"},
        status => "ready",
    };
}
```

Rules:

- Patterns use Router::Simple syntax.
- The pattern is relative to the API PSP mount path.
- A file `api.psp` serving `/api/order/42` uses `pattern="/order/:id"`, not `/api/order/:id`.
- Multiple `<api>` elements can define multiple routes in one file.
- The second handler argument is the route match/destination hash. Read query/body parameters separately through `$self->CGI()`.
- `destination`, `dest`, and `data` can supply destination data.
- `option`/`options` and `constraint`/`constraints` supply Router::Simple registration options.
- `canonical` controls JSON key ordering.

PSGI and PAGI can discover a PSP file by walking an API-style route path. That discovery is cached in process; restart workers after adding, moving, or removing API page files. Apache does not provide the same extensionless fallback without rewrite/routing configuration.

WebDyne API pages are intentionally lightweight. Use a dedicated application/API framework when middleware, authentication policy, negotiation, schema validation, or complex routing dominates the endpoint.

## HTMX Fragment Pages

`<htmx>` renders only for an HX/AJAX request unless forced:

```html
<htmx>
<perl handler="status">
<p class="status">${message}</p>
</perl>
</htmx>

__PERL__

sub status {
    my $self=shift();
    return $self->render(message => load_status());
}
```

A dedicated fragment page does not need `<start_html>`.

Use `bare` or `compact` when the source is exclusively a fragment endpoint:

```html
<htmx bare>
<perl handler="result"><p>${message}</p></perl>
</htmx>
```

This compacts away non-HTMX page structure during compilation. Use a normal `<htmx>` when one PSP intentionally serves both its full page and an HX fragment.

Useful behavior:

- `handler` uses the same handler contract as `<perl>`.
- `perl` treats the HTMX body as inline Perl.
- `display` chooses a fragment for a true dynamic value.
- `force` renders without an HX request, primarily for development or deliberate direct access.
- Only one HTMX section is returned for a request. Use `display` to make the selection explicit or put fragments in separate files.

Example multi-fragment selection:

```html
<htmx display="+{local}">Local: <? scalar localtime() ?></htmx>
<htmx display="+{utc}">UTC: <? scalar gmtime() ?></htmx>
```

The browser page must load HTMX itself. `<start_html htmx>` uses the configured shortcut; an explicit script tag/version is clearer when reproducibility matters.

### HTMX Attribute Quoting

WebDyne emits attributes with double quotes even if source markup used single quotes. Raw JSON that depends on single-quoted outer HTML attributes can become invalid.

Prefer the HTMX JavaScript expression form:

```html
<button
  hx-get="status.psp"
  hx-vals="js:{ order_id: this.dataset.orderId }"
  data-order-id="42">
  Refresh
</button>
```

Do not assume this remains safely nested:

```html
<!-- Fragile: quote normalization changes the attribute -->
<button hx-vals='{ "order_id": 42 }'>
```

## SSE Under PAGI

SSE requires PAGI and an async handler declared by `<start_html>`:

```html
<start_html title="Updates" sse>

__PERL__

use HTTP::Status qw(HTTP_OK);
use Future::AsyncAwait;

async sub sse {
    my ($self, $param_hr)=@_;
    my $sse_or=$self->r()->sse();
    my $channel=$param_hr->{"channel"} || "default";

    await $sse_or->start(
        status  => HTTP_OK,
        headers => [
            ["X-Accel-Buffering" => "no"],
            ["Content-Encoding"  => "identity"],
        ],
    );

    await $sse_or->send_event(
        event => "changed",
        data  => $channel,
    );

    $sse_or->close();
}
```

Bare `sse` means `sse="sse"`. A named handler uses `<start_html sse="stream">`. A WebDyne meta declaration is the lower-level alternative.

The handler receives:

- `$self`: the page object associated with the connection.
- `$param_hr`: `$self->CGI()->Vars()` captured when the stream is established.

Always use the explicit parameter hash in async code. The normal `%_` shortcut is dynamically localized around synchronous eval callbacks; it is not a reliable state carrier after an `await` suspension.

Start the event stream once, avoid proxy compression/buffering where appropriate, send events, and close on terminal state or disconnect. Do not leave a periodic producer active after the client no longer needs updates.

## HTMX Plus SSE

For state backed by a database, queue, or service, SSE should usually carry invalidation rather than duplicate the rendered state:

1. SSE sends a small `changed` event.
2. The HTMX SSE extension turns the event into a fragment request.
3. The fragment PSP loads current backend state and returns HTML.
4. A terminal event closes the browser and server stream.

Browser markup:

```html
<script src="https://unpkg.com/htmx.org@2.0.4/dist/htmx.min.js"></script>
<script src="https://unpkg.com/htmx-ext-sse@2.2.2/sse.js"></script>

<main
  hx-ext="sse"
  sse-connect="order.psp?order_id=!{! order_id(@_) !}"
  sse-close="order-complete">

  <div
    id="order-status"
    hx-get="order_status.psp?order_id=!{! order_id(@_) !}"
    hx-trigger="sse:order-changed, sse:order-complete"
    hx-swap="innerHTML">
    <p>Waiting for an update...</p>
  </div>
</main>
```

Fragment endpoint:

```html
<htmx bare>
<perl handler="status">
<section class="status ${done}">
  <p>${message}</p>
  <progress value="${percent}" max="100"></progress>
</section>
</perl>
</htmx>
```

This keeps transport events small and makes the fragment endpoint independently renderable/testable. Sending full state over SSE is still reasonable when the event itself is the authoritative representation and no follow-up request is needed.

Use the official HTMX SSE extension rather than custom EventSource JavaScript when the page otherwise uses HTMX and the extension expresses the required lifecycle.

Close both sides:

- Server sends a named terminal event and calls `$sse_or->close()`.
- The client container uses `sse-close="that-event"`.

Without the client close behavior, browser reconnect rules can create a new SSE request after the server closes. Without the server close behavior, the periodic callback can continue polling the backend.

## WebSockets Under PAGI

Declare the handler with `ws`:

```html
<start_html title="Socket" ws>

__PERL__

use Future::AsyncAwait;

async sub ws {
    my ($self, $param_hr)=@_;
    my $room=$param_hr->{"room"} || "lobby";
    my $r=$self->r();

    await $r->{"send"}->({type => "websocket.accept"});

    while (my $event=await $r->{"receive"}->()) {
        last if $event->{"type"} eq "websocket.disconnect";
        next unless $event->{"type"} eq "websocket.receive";

        await $r->{"send"}->({
            type => "websocket.send",
            text => join(":", $room, $event->{"text"} || ""),
        });
    }
}
```

Bare `ws` means `ws="ws"`. The second argument is the connection-time CGI parameter hash, with the same async scope rule as SSE.

Use the request adapter facilities supported by the repository/version in use. Accept exactly once, handle disconnect explicitly, validate message types/content, and avoid retaining page/request objects after connection completion.

## Runtime And Test Limits

- SSE and WebSockets do not work under Apache, PSGI, or fake rendering; use PAGI.
- `wdrender` can compile the page and exercise ordinary HTTP/HTMX output, but it cannot prove a long-lived stream/socket lifecycle.
- Use PAGI integration tests or run a PAGI server for end-to-end SSE/WebSocket behavior.
- Test connection query parameters, initial response headers, event names/data, terminal close behavior, and disconnect cleanup.
