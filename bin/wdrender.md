# wdrender(1) #

# NAME #

wdrender - parse and render WebDyne pages

# SYNOPSIS #

`wdrender [OPTIONS] FILE`

# Description #

The  `wdrender`  command displays the HTML that would be generated from a psp page using the WebDyne perl module.

By default  `wdrender`  will use the internal WebDyne handler when building the output, but can optionally use other WebDyne
 modules \(such as  `WebDyne::Chain` ) by using the `--handler`  option..

# Options #

* **-h, --help**

    Show brief help message.

* **--handler**

    Use a different WebDyne handler module. Currently the only other handler module available is `WebDyne::Chain` .

* **--status**

    Specify the status.

* **--header**

    Include headers in the output.

* **--error**

    Specify the error format \(default: text).

* **--headers_out | --header_out**

    Specify headers to include in the output.

* **--headers_in | --header_in**

    Specify headers to include in the input.

* **--outfile**

    Specify the output file.

* **--repeat | --r | --num | --n**

    Specify the number of times to repeat the rendering.

* **--loop**

    Enable looping. Used for leak testing.

* **--man**

    Display the full manual.

* **--version**

    Display the script version and exit.

# Examples #

```sh
# Show the HTML rendered version of time.psp
wdrender time.psp
```

```sh
# Show the HTML rendered version of time.psp with headers
wdrender --header time.psp
```

```sh
# Show the HTML rendered version of time.psp chaining with the WebDyne::Session module
WebDyneChain=WebDyne::Session wdrender --header --handler WebDyne::Chain time.psp
```

# Notes #

The  `wdrender`  command will attempt to build the HTML as faithfully as possible from the command line environment, but may
 not be able to exactly duplicate the HTML generated under a real Web
 Server. As an example if a psp page takes advantge of the Apache request
 handler when generating HTML, the  `wdrender`  commend will not be able to duplicate that environment.

# Author #

Written by Andrew Speer,  <andrew@webdyne.org>

# Copying #

Copyright &copy; 2008-2010 Andrew Speer. Free use of this software is granted under the terms of the GNU General Public License \(GPL)