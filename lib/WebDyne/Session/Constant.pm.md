# WebDyne::Session::Constant #

# NAME #

WebDyne::Session::Constant - session-cookie constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Session::Constant;
```

# DESCRIPTION #

`WebDyne::Session::Constant` defines the session-layer constant used by `WebDyne::Session` when creating or reading the browser cookie that carries the session identifier.

# CONSTANTS #

* **WEBDYNE_SESSION_ID_COOKIE_NAME ('session')**

    Name of the cookie used to store the WebDyne session identifier on the client.

* **WEBDYNE_SESSION_COOKIE_PATH ('/')**

    Path attribute used when setting the WebDyne session cookie.

* **WEBDYNE_SESSION_COOKIE_SECURE (1)**

    Add the `Secure` attribute to newly generated session cookies. Set to `0` for plain HTTP development deployments.

* **WEBDYNE_SESSION_COOKIE_HTTPONLY (1)**

    Add the `HttpOnly` attribute to newly generated session cookies.

* **WEBDYNE_SESSION_COOKIE_SAMESITE ('Lax')**

    SameSite attribute used for newly generated session cookies. Set to an empty value to omit the attribute.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
