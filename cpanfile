requires 'CGI::Simple';
requires 'Capture::Tiny';
requires 'Carp', '1.50';
requires 'Crypt::URandom';
requires 'Devel::Confess';
requires 'Digest::MD5';
requires 'Env::Path';
requires 'File::Temp';
requires 'HTML::Element';
requires 'HTML::Entities';
requires 'HTML::Tagset';
requires 'HTML::Tiny';
requires 'HTML::TreeBuilder';
requires 'HTTP::Status';
requires 'HTTP::Headers::Fast';
requires 'HTTP::Headers::Util';
requires 'HTTP::Negotiate';
requires 'HTTP::AcceptLanguage';
requires 'HTTP::Request';
requires 'HTTP::Request::Common';
requires 'Hash::MultiValue';
requires 'IO::String';
requires 'JSON';
requires 'Module::Reload';
requires 'Router::Simple';
requires 'Storable';
requires 'Sub::Util';
requires 'Term::ANSIColor';
requires 'Text::Template';
requires 'Tie::IxHash';
requires 'Time::HiRes';
requires 'URI';
requires 'URI::Escape';
requires 'perl', '5.006';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
    requires 'Tie::File';
};

on test => sub {
    requires 'Algorithm::Diff';
    requires 'Test::Deep';
    requires 'Test::Differences';
    requires 'Test::More', '0.88';
    requires 'Text::Diff';
};
