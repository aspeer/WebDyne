
# NAME

wdapacheinit - Install or uninstall WebDyne Apache configuration files

# SYNOPSIS

`wdapacheinit [--option]`

`wdapacheinit --cache /var/www/cache`

`wdapacheinit --print`

`wdapacheinit --uninstall`

# DESCRIPTION

`wdapacheinit` will install or uninstall the WebDyne Apache configuration files. 
It will create the necessary configuration files and directories for Apache to serve WebDyne pages. 
The script will also attempt to set the correct ownership and permissions on the cache directory.

Command-line options are copied into uppercase environment variables before the Apache discovery constants are loaded, so supplied options override the detected values.

NOTE: Apache must be restarted after running this script !

# OPTIONS

- `--help | -?`
  Display a brief help message and exit.

- `--man`
  Display the full manual.

- `--apache_uname=USER | --apache-uname=USER | --uname=USER`
  Specify the Apache user name.

- `--apache_gname=GROUP | --apache-gname=GROUP | --gname=GROUP`
  Specify the Apache group name.

- `--httpd_bin=PATH | --httpd-bin=PATH | --httpd=PATH`
  Specify the path to the httpd binary.

- `--dir_apache_conf=DIR | --dir-apache-conf=DIR | --apache_conf=DIR | --apache-conf=DIR | --conf=DIR`
  Specify the directory for Apache configuration files.

- `--dir_apache_modules=DIR | --dir-apache-modules=DIR | --apache_modules=DIR | --apache-modules=DIR | --modules=DIR`
  Specify the directory for Apache modules.

- `--file_mod_perl_lib=PATH | --file-mod-perl-lib=PATH | --mod_perl_lib=PATH | --mod-perl-lib=PATH | --mod_perl=PATH | --mod-perl=PATH`
  Specify the path to the mod_perl library.

- `--mp2`
  Use mod_perl 2.

- `--webdyne_cache_dn=DIR | --webdyne-cache-dn=DIR | --webdyne_cache=DIR | --webdyne-cache=DIR | --cache_dn=DIR | --cache-dn=DIR | --cache=DIR | --dir_webdyne_cache=DIR | --dir-webdyne-cache=DIR`
  Specify the directory for WebDyne cache.

- `--silent`
  Suppress installer status messages.

- `--setcontext`
  When SELinux is detected, change the context of module library files that would otherwise only generate a warning. Cache directory context handling is attempted independently when SELinux support is available.

- `--uninstall`
  Uninstall the WebDyne Apache configuration.

- `--text | --print`
  Print the generated WebDyne Apache include configuration and exit without completing the install.

- `--dump_opt | --dump-opt | --opt`
  Dump the processed option hash and exit.

- `--version`
  Display the script version and exit.


# EXAMPLES

The script will attempt to automatically detect the correct settings for your system, so in most cases you will not need to specify any options. However, you can override the defaults by specifying the options on the command line.

`wdapacheinit`

`wdapacheinit --cache /var/www/cache`

`wdapacheinit --print`

`wdapacheinit --uninstall`

# NOTES

Apache installation of WebDyne is split into two components. The first is the installation of the WebDyne Apache configuration files, which is done by this script. The second is the installation of the configuration files for the WebDyne framework to enable rendering of WebDyne pages.

The generated WebDyne Perl configuration contains variables that can be set to change the behaviour of the WebDyne system.

Where Apache uses a conf.d-style include directory, the generated WebDyne Apache include is written there and the main Apache configuration file is not changed. Where no such include directory is detected, the script updates the main Apache configuration between WebDyne delimiter markers.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
