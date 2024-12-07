requires 'CGI';
requires 'CGI::Util';
requires 'Digest::MD5';
requires 'Env::Path';
requires 'File::Temp';
requires 'HTML::Entities';
requires 'HTML::Tagset';
requires 'HTML::TreeBuilder';
requires 'HTTP::Status';
requires 'Storable';
requires 'Text::Template';
requires 'Tie::IxHash';
recommends 'URI';
recommends 'Win32::TieRegistry';
suggests 'APR::Table';
suggests 'Apache2';
suggests 'Apache2::Const';
suggests 'Apache2::Log';
suggests 'Apache2::Response';
suggests 'Apache2::ServerUtil';
suggests 'Apache2::SubRequest';
suggests 'Apache::Const';
suggests 'Apache::Constants';
suggests 'Apache::Log';
suggests 'Apache::Response';
suggests 'Apache::ServerUtil';
suggests 'Apache::SubRequest';
suggests 'Apache::Table';
suggests 'Apache::compat';
suggests 'ExtUtils::MM';
suggests 'Module::Reload';
suggests 'Time::HiRes';
suggests 'mod_perl';
suggests 'mod_perl2';

on configure => sub {
    requires 'perl', '5.006';
};

on test => sub {
    requires 'Digest::MD5';
    requires 'File::Temp';
    requires 'Test::More';
};
