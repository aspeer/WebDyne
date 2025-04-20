
# NAME

wdrender - Compile and/or show compiled version of WebDyne pages

# SYNOPSIS

`wdrender [--option] <filename>`

`wdrender time.psp`

# DESCRIPTION

`wdrender` will compile and/or show the compiled version of WebDyne HTML page.
It supports various command-line options to customize the compilation process. Output is printed to STDOUT in the form of a Perl data structure representing
the compiled .psp page.

# OPTIONS

- `--help | -?`
  Display a brief help message and exit.

- `--handler`
  Specify the handler to use (default: WebDyne).

- `--status`
  Specify the status.

- `--header`
  Include headers in the output.

- `--error`
  Specify the error format (default: text).

- `--headers_out | --header_out`
  Specify headers to include in the output.

- `--headers_in | --header_in`
  Specify headers to include in the input.

- `--outfile`
  Specify the output file.

- `--repeat | --r | --num | --n`
  Specify the number of times to repeat the rendering.

- `--loop`
  Enable looping. Used for leak testing.

- `--man`
  Display the full manual.

- `--version`
  Display the script version and exit.


# EXAMPLES

```sh
# Show the HTML rendered version of time.psp
wdrender time.psp
```

```sh
# Show the HTML rendered version of time.psp with headers
wdrender --header time.psp
```

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>