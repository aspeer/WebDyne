# WebDyne::Constant(3pm) #

# NAME #

WebDyne::Constant - WebDyne module that sets constants and defaults for WebDyne processing

# SYNOPSIS #

```
#!/usr/bin/env perl
#
use WebDyne::Constant;
print $WEBDYNE_DTD
```

    # Dump all constant settings for review
    #
    $ perl -MWebDyne::Constant=dump

# Description #

This module provides a list of configuration constants used in the WebDyne code. These constants are used to configure the behavior of the WebDyne module and can be accessed by importing the module and referencing the constants by name. Constants can be configured to different values by overriding values in local configuration files, setting environment
 variables, command line options, or Apache directives.

Common uses for modifying constant values allow for:

* Changing default language from en-US to something else.

* Modifying or adding new meta-data or default headers to output

* Adding default style-sheets or other inclusions to all output files

Default values for these configuration constants can be updated the following locations:

1. /etc/webdyne.conf.pl

2. $HOME/.webdyne.conf.pl

3. $DOCUMENT_ROOT/.webdyne.conf.pl

As a special case when running under PSGI environments, if WEBDYNE_DIR_CONFIG_CWD_LOAD is true \(which it is by default) then each directory that a \.psp file is run from is checked for the \.webdyne.conf.pl file \- but only WEBDYNE_DIR_CONFIG entries from the file are loaded. This allows for configuration of settings such a WebDyneChain modules to load, WebDyneTemplate
 configuration etc. on a per directory basis

The WebDyne::Constant module is sub-classed by other WebDyne modules, and the values for any constants in the WebDyne::&lt;Module&gt;::Constant family of modules can be overridden by creating or updating one of the above configuration files. Here is a sample configuration file:

```
$_={

    #  Update config constants for WebDyne::Constant module
    #
    'WebDyne::Constant' => {

        #  Where the cache directory will live
        #
        WEBDYNE_CACHE_DN            => '/tmp',
 
        #  The attributes below will be added to any <start_html> tag, effectively
        #  adding two stylesheets to every page
        #
        WEBDYNE_START_HTML_PARAM    => {
          style => [qw(
            https://cdn.jsssdelivr.net/npm/@picocss/pico@2/css/pico.classless.m
            /style.css
          )]
        },

        #  Enable extended error display
        #
        WEBDYNE_ERROR_SHOW_EXTENDED => 1,

        #  Update CGI upload capacity to 2GB
        #
        WEBDYNE_CGI_POST_MAX        => (2048*1024),

        #  Handle examples directory differently
        #
        WEBDYNE_DIR_CONFIG => {
            '/examples' => {
                'WebDyneHandler'    => 'WebDyne::Chain',
                'WebDyneChain'      => 'WebDyne::Session',
            },
        },

  },

  #  And for WebDyne::Session module
  #
  'WebDyne::Session::Constant' => {
      WEBDYNE_SESSION_ID_COOKIE_NAME => 'mysession'  
  },
};
```

> **WARNING**
> 
> Ensure the configuration file has the correct syntax by checking the Perl interpreter doesn&#39;t throw any errors. Use  `perl -c -w`  to check syntax:
> 
>     # perl -c -w /etc/webdyne.conf.pl
>     /etc/webdyne.conf.pl syntax OK
>     # perl -c -w ~/.webdyne.conf.pl
>     /home/<user>/.webdyne.conf.pl OK
> 
>

# CONSTANTS #

The following commonly adjusted configuration constants are defined. The default value of the configuration item is provided after the constant name. Most can be overridden or adjusted; where they are read-only this is noted.

* **WEBDYNE_CACHE_DN ()**

    Directory where compiled pages are stored. Unset by default on command line, usually set to temporary directory by installer or PSGI handler. Pages that are compiled from \.psp source into an intermediate data structure in Storable format are stored in this location.

* **WEBDYNE_STARTUP_CACHE_FLUSH (1)**

    Flush cache files at startup. If set will delete all cache files and force re-read and recompile of all source \.psp files at startup. Recommended to leave at \(1)

* **WEBDYNE_CACHE_CHECK_FREQ (256)**

    Perl process frequency \(number of runs) to check cache for excess entries and clean any that exceed the cache high water mark.

* **WEBDYNE_CACHE_HIGH_WATER (64)**

    High water mark for cache entries. Once this limit is reaped cache entries will be deleted down to the low water mark level.

* **WEBDYNE_CACHE_LOW_WATER (32)**

    Low water mark for cache entries. Once high water mark is reached cached entries will be deleted down to this level.

* **WEBDYNE_CACHE_CLEAN_METHOD (1)**

    Method to clean cache \(0: last used time, 1: frequency of use).

* **WEBDYNE_EVAL_SAFE (0)**

    Type of eval code to run \(0: Direct, 1: Safe). All dynamic components of a \.psp page are run in an eval block. Running using eval via the Safe module is experimental.

* **WEBDYNE_EVAL_SAFE_OPCODE_AR => [':default']**

    Opcode set to allow when running in Safe mode.

* **WEBDYNE_EVAL_USE_STRICT ('use strict qw(vars)')**

    Prefix eval code with strict pragma via this string

* **WEBDYNE_STRICT_VARS (1)**

    Use strict variable checking. If any variables are referenced which are not populated in a render(variable=&gt;&lt;value&gt;) call an error will thrown.

* **WEBDYNE_AUTOLOAD_POLLUTE (0)**

    Pollute WebDyne class with method references for minor speedup. Saves AUTOLOAD trying to find method in call stack but at the price of potentially clashing with an inbuilt method. Use with care.

* **WEBDYNE_DUMP_FLAG (0)**

    Flag to display current CGI value and other information if &lt;dump&gt; tag is used.

* **WEBDYNE_CONTENT_TYPE_HTML ('text/html')**

    Content-type header for text/html.

* **WEBDYNE_CONTENT_TYPE_TEXT ('text/plain')**

    Content-type header for text/plain.

* **WEBDYNE_CONTENT_TYPE_HTML_ENCODED ('text/html; charset=UTF-8')**

    Fully encoded Content-type header for HTML responses.

* **WEBDYNE_CONTENT_TYPE_TEXT_ENCODED ('text/plain; charset=UTF-8')**

    Fully encoded Content-type header for plain text responses.

* **WEBDYNE_CONTENT_TYPE_JSON_ENCODED ('application/json; charset=UTF-8')**

    Fully encoded Content-type header for JSON responses.

* **WEBDYNE_CONTENT_TYPE_JSON ('application/json')**

    Content-type header for text/json

* **WEBDYNE_SCRIPT_TYPE_EXECUTABLE_HR**

    Script types which are executable on the browser and won&#39;t have substitution imposed on variables that match WebDyne syntax \(e.g. ${foo}). includes:

* text/javascript

* application/javascript

* module

* **WEBDYNE_HTML_CHARSET ('UTF-8')**

    Character set for HTML.

* **WEBDYNE_DTD ('<!DOCTYPE html>')**

    DTD to use when generating HTML.

* **WEBDYNE_META ({charset => 'UTF-8', viewport' => 'width=device-width, initial-scale=1.0'})**

    Meta information for HTML

* **WEBDYNE_CONTENT_TYPE_HTML_META (0)**

    Include a Content-Type meta tag.

* **WEBDYNE_HTML_PARAM ({lang => 'en'})**

    Default &lt;html&gt; tag parameter attributes

* **WEBDYNE_START_HTML_PARAM ()**

    Default attributes for any &lt;start_html&gt; tags, e.g. include_style=&gt;[&#39;foo.css&#39;, &#39;bar.css&#39;]. These will be inserted automatically into any start_html tag seen in any \.psp page.

* **WEBDYNE_START_HTML_PARAM_STATIC (1)**

    Make include/other sections in start_html tag static, i.e. load them at compile time and they never change. Make undef to force re-include every page load

* **WEBDYNE_START_HTML_SHORTCUT_HR (&lt;HashRef&gt;)**

    Shortcut attribute mappings for `start_html`, including built-in helpers such as `pico`, `htmx`, and `alpine`.

* **WEBDYNE_HEAD_INSERT ()**

    Anything that should be added in &lt;head&gt; section. Will be inserted verbatim before &lt;/head&gt;. No interpolation or variables, simple text string only. Useful for setting global stylesheet, e.g. &lt;link href=&quot;https://cdn.jsdelivr.net/npm/water.css@2/out/water.css&quot; rel=&quot;stylesheet&quot;&gt;. Will be added to all &lt;head&gt; sections
 universally.

* **WEBDYNE_COMPILE_IGNORE_WHITESPACE (1)**

    Ignore ignorable whitespace in compile.

* **WEBDYNE_COMPILE_NO_SPACE_COMPACTING (0)**

    Disable space compacting in compile.

* **WEBDYNE_COMPILE_P_STRICT (1)**

    Use strict parsing in compile.

* **WEBDYNE_COMPILE_IMPLICIT_BODY_P_TAG (1)**

    Implicitly add &lt;body&gt; and &lt;p&gt; tags in compile

* **WEBDYNE_STORE_COMMENTS (1)**

    Store and render comments.

* **WEBDYNE_NO_CACHE (1)**

    Send no-cache headers.

* **WEBDYNE_WARNINGS_FATAL (0)**

    Treat any warnings as fatal errors.

* **WEBDYNE_CGI_DISABLE_UPLOADS (0)**

    Disable CGI uploads. They are enabled by defaults

* **WEBDYNE_CGI_POST_MAX (524288)**

    Max post size for CGI \(512KB).

* **WEBDYNE_CGI_PARAM_EXPAND (1)**

    Expand CGI parameters found in CGI names.

* **WEBDYNE_CGI_AUTOESCAPE (0)**

    Disable CGI autoescape of form fields.

* **WEBDYNE_ERROR_TEXT (0)**

    Use text errors rather than HTML.

* **WEBDYNE_ERROR_SHOW (1)**

    Show errors.

* **WEBDYNE_ERROR_SHOW_EXTENDED (0)**

    Show extended error information, including backtraces and source code

* **WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW (1)**

    Show error source file context.

* **WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE (4)**

    Number of lines to show before error context.

* **WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST (4)**

    Number of lines to show after error context.

* **WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX (80)**

    Max length of source line to show in output.

* **WEBDYNE_ERROR_SOURCE_FILENAME_SHOW (1)**

    Show filename in error output.

* **WEBDYNE_ERROR_SOURCE_FILENAME_FULL (0)**

    Show full source filename rather than the shortened display form.

* **WEBDYNE_ERROR_BACKTRACE_SHOW (1)**

    Show backtrace in error output.

* **WEBDYNE_ERROR_BACKTRACE_SHORT (0)**

    Show brief backtrace.

* **WEBDYNE_ERROR_BACKTRACE_FULL (0)**

    Show a fuller backtrace in error output.

* **WEBDYNE_ERROR_EVAL_CONTEXT_SHOW (1)**

    Show eval trace in error output.

* **WEBDYNE_ERROR_CGI_PARAM_SHOW (1)**

    Show CGI parameters in error output.

* **WEBDYNE_ERROR_ENV_SHOW (1)**

    Show environment variables in error output.

* **WEBDYNE_ERROR_WEBDYNE_CONSTANT_SHOW (1)**

    Show WebDyne constants in error output.

* **WEBDYNE_ERROR_URI_SHOW (1)**

    Show URI in error output.

* **WEBDYNE_ERROR_VERSION_SHOW (1)**

    Show version in error output.

* **WEBDYNE_ERROR_INTERNAL_SHOW (0)**

    Show internal WebDyne error details intended mainly for debugging.

* **WEBDYNE_ERROR_SHOW_ALTERNATE` ('error display disabled - enable WEBDYNE_ERROR_SHOW to show errors, or review web server error log.')**

    Alternate error message if error display is disabled.

* **WEBDYNE_HTML_DEFAULT_TITLE ('Untitled Document')**

    Default title for HTML documents.

* **WEBDYNE_HTML_TINY_MODE ('html')**

    Mode for HTML::Tiny object used for generating output \(XML or HTML).

* **WEBDYNE_RELOAD (0)**

    Development mode \- recompile loaded modules.

* **WEBDYNE_JSON_CANONICAL (1)**

    Use JSON canonical mode.

* **WEBDYNE_JSON_PRETTY (0)**

    Enable pretty-printed JSON output by default.

* **WEBDYNE_HTTP_HEADER (<HashRef>)**

    Default HTTP response headers to send. Includes:

* Content-type: text/html; charset=UTF-8

* Cache-Control: no-cache, no-store, must-revalidate

* Pragma: no-cache

* Expires: 0

* X-Content-Type-Options: nosniff

* X-Frame-Options: SAMEORIGIN

* **WEBDYNE_API_ENABLE (1)**

    Enable support for the &lt;api&gt; tag. Will cause slight slow-down as routes are converted to \.psp file names. Enabled by default.

* **WEBDYNE_ALPINE_VUE_ATTRIBUTE_HACK_ENABLE ('x-on')**

    Converts @click=&quot;dosomething()&quot; attributes to x-on:click=&quot;dosomething()&quot; in tags as HTML::Parser does not support the &#39;@&#39; character in tag attributes.

* **WEBDYNE_HTTP_HEADER_AJAX_HR ({ hx-request=>1, x-alpine-request=>1 })**

    List of HTTP request headers that denote the request is part of an AJAX \(e.g. HTMX) request and only partial HTML response is required.

* **WEBDYNE_HTTP_HEADER_AJAX_AR (&lt;ArrayRef&gt;)**

    Array form of the AJAX request header names derived from `WEBDYNE_HTTP_HEADER_AJAX_HR`.

* **WEBDYNE_HTMX_FORCE (0)**

    Force HTMX-oriented partial rendering behaviour even without an HTMX request header.

* **WEBDYNE_PSP_EXT (.psp)**

    Extension for \.psp pages. Do not change unless you know what you are doing.

* **WEBDYNE_MIME_TYPE_HR (<HashRef>)**

    Very minimal MIME type hash used by lookup_file function. See file for default content, usual definitions for text, images, style-sheets, PDF etc.

* **WEBDYNE_DIR_CONFIG ()**

    Hash ref that contains location based hierarchy of configuration variables similar to that returned by Apache mod_perl dir_config module. See test \(t) directory in source for example.

* **WEBDYNE_DIR_CONFIG_CWD_LOAD (1)**

    Enable loading of WEBDYNE_DIR_CONFIG hash ref from the current \.psp file working directory if a \.webdyne.conf.pl file is present.

* **WEBDYNE_CONF_HR (<HashRef>)**

    Read-only value as hash reference showing location of files used to create the values for constants in this module.

* **WEBDYNE_CONF_FN ('webdyne.conf.pl')**

    Basename of the standard WebDyne local configuration file.

* **WEBDYNE_HTML_TIDY (0)**

    Enable HTML tidy post-processing by default.

* **WEBDYNE_HTML_NEWLINE (0)**

    Control whether WebDyne adds extra newlines to output.

* **WEBDYNE_PAGI (auto-detected)**

    Indicates whether the PAGI support module is currently loaded.

* **WEBDYNE_PSGI (auto-detected)**

    Indicates whether the PSGI support module is currently loaded.

* **WEBDYNE_DEFAULT_TEST_FN**

    Absolute path to the built-in WebDyne test page.

* **WEBDYNE_DEFAULT_INDEX_FN**

    Absolute path to the built-in WebDyne index page.

* **MP2 (mod_perl version)**

    Mod_perl level. Auto-detected, do not change unless you know what you are doing.

* **MOD_PERL (mod_perl version)**

    Mod_perl environment runtime detected. Do not change unless you know what you are doing
