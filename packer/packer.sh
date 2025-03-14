pp -I ~/perl5/lib/perl5/ -M WebDyne -M Plack::Middleware::Lint -M Plack::Middleware::StackTrace -M Plack::Middleware::AccessLog \
-M Plack::Loader -M Plack::Handler::Standalone -o webdyne.psgi.pp ~/perl5/bin/webdyne.psgi
