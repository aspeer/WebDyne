README

# Introduction #

WebDyne is a dynamic content generation engine for Apache/mod_perl and PSGI web servers \(such as Plack and Starman). HTML documents with
 embedded Perl code are processed to produce dynamic HTML output. 

An installer is included in the base WebDyne module for Apache, or a PSGI variant is included for use with Plack. Once WebDyne is installed any
 file with a  `.psp`  extension is treated as a WebDyne source file. It is parsed for WebDyne tags \(such as `<perl>`  and  `<block>` ) which are interpreted and executed on the server as appropriate to generate a
 compliant HTML document. The resulting output is then sent to the browser.

Once parsed paged are are optionally stored in a partially compiled format, speeding up subsequent processing. The aim of WebDyne is to make
 coding web pages with Perl components a faster, easier and more enjoyable
 experience.

# Getting Started #

Install the WebDyne module from CPAN using cpanminus or cpan, and install Plack for the PSGI version.

```bash
#  Use cpan if you don't have cpanm
#
$ cpanm WebDyne
Building and testing Webdyne-2.04 ... OK

$ cpanm Plack
Building and testing Webdyne-1.0051 ... OK
```

Run the PSGI variant in test mode and connect to the server to check that it is working

```bash
$ webdyne.psgi --test
HTTP::Server::PSGI: Accepting connections at http://0:5000/
```

Create an app.psp file in the appropriate web server home directory. Don&#39;t be put off by the shortcut &lt;start_html&gt; tag, you can still use
 traditional tags if you like.

```html
# Create file called app.psp with this content.
#
<start_html>
The local server time is: <perl>localtime()</perl>
```

Run the PSGI variant against that directory

```bash
# 
$ webdyne.psgi /location/of/app.psp
HTTP::Server::PSGI: Accepting connections at http://0:5000/

```

