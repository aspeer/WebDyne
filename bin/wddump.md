
# NAME

wddump - This script is used to dump the compiled version of WebDyne pages, as stored in the cache dir.

# SYNOPSIS

`wddump [filename]`

`wddump /var/cache/webdyne/0dc461f7a383fda853fcc6c5190704e`

# DESCRIPTION

This script will dump out (in Data::Dumper format) the contents of a compiled WebDyne page. The compiled page is stored in the cache directory and is a binary file in Storable format. 
This script will read the file and dump out the contents in a Data::Dumper format. It can we used to debug the compiled version of a page.

# OPTIONS

- `--help | -?`
  Display a brief help message and exit.

- `--man`
  Display the full manual.

- `--version`
  Display the script version and exit.

# EXAMPLES

```sh
# Dump the compiled version of a page from cache
wddump /var/cache/webdyne/0dc461f7a383fda853fcc6c5190704e

# Output
#
$VAR1 = [
  {
    'manifest' => [
      '/var/www/html/time.psp'
    ]
  },
  [
    '<!DOCTYPE html><html lang="en"><head><title>Untitled Document</title><meta charset="UTF-8"></head>
<body><p>',
    [
      'subst',
      undef,
      [
        '!{! localtime !}'
      ],
      undef,
      2,
      2,
      \$VAR1->[0]{'manifest'}[0]
    ],
    '</p></body></html>'
  ]
];
````

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>

