
# NAME

wdcompile - This script is used to compile and/or show the compiled version of WebDyne HTML scripts at various stages of processing.

# SYNOPSIS

`wdcompile [--option] <filename>`

`wdcompile --stage0 time.psp`

# DESCRIPTION

`wdcompile` will compile and/or show the compiled version of WebDyne HTML scripts at various stages of processing. 
It supports various command-line options to customize the compilation process. Output is printed to STDOUT in the form of a Perl data structure representing
the compiled .psp page.

# OPTIONS

- `--stage0 | --0`
  Compile to stage 0.

- `--stage1 | --1`
  Compile to stage 1.

- `--stage2 | --2`
  Compile to stage 2.

- `--stage3 | --3`
  Compile to stage 3.

- `--stage4 | --4`
  Compile to stage 4.

- `--stage5 | --5 | --final`
  Compile to stage 5 (final stage - default option).

- `--meta`
  Print metadata.

- `--data`
  Print data.

- `--nomanifest`
  Do not generate a manifest.

- `--dest | --dest_fn`
  Specify the destination file.

- `--all`
  Print all data.

- `--timestamp`
  Include a timestamp.

- `--version`
  Display the script version and exit.

- `--help | -?`
  Display a brief help message and exit.

- `--man`
  Display the full manual.


# EXAMPLES

```sh
# Show the compiled version of time.psp with all optimizations
wdcompile time.psp
```

```sh
# Show the compiled version of time.psp with the full HTML tree before optimization
wdcompile --stage0 time.psp
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