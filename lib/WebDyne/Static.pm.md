# WebDyne::Static(3pm) #

# NAME #

WebDyne::Static - WebDyne module to flag pages as static and compile once to HTML

# SYNOPSIS #

```
#  Sample time.psp compiled to static HTML. Every time this page is requested it will show
#  the same time - the time it was first run/compiled
#
<start_html>
This page was first loaded at <? localtime ?>
__PERL__
use WebDyne::Static;
```

# DESCRIPTION #

The WebDyne::Static module will flag that all dynamic components of a page should be run at compile time, and the resulting HTML saved as a static file which will be served on subsequent requests.

The WebDyne framework will monitor for changes in the source file and recompile to a new HTML if the source \.psp file is updated.

# METHODS #

* **static()**

    Get or set the static attribute for this page. When setting the static attribute for a page it is only set for that instance of the page. To set a page as permanently static \(except on source file update) use the WebDyne::Static module as per synopsis, or update the meta data via $self-&gt;meta-&gt;{&#39;static&#39;}=1;

# OPTIONS #

WebDyne::Static does not expose any options to the import function when called via use.

# AUTHOR #

Andrew Speer &lt;andrew.speer@isolutions.com.au&gt; and contributors.

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright \(c) 2026 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it underthe same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/&gt;