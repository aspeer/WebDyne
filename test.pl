use strict;
use Data::Dumper;

use CGI qw(-no_xhtml :form);
use WebDyne::HTML::Tiny;

my $c_or=CGI->new();
my $h_or=WebDyne::HTML::Tiny->new(mode=>'html');

#die Dumper(\%CGI::EXPORT_TAGS);

my %cgi_ignore=map { $_=>1 } qw(
    autoEscape
    tmpFileName
    uploadInfo
);


my %cgi_test=(

    checkbox        => [{
        name        => 'foo',
        value       => 'var',
        checked     => [],
        disabled    => [],
        label       => 'Foo'
    }],

    checkbox_group  => [{
        name        => 'game',
        values      => [qw(checkers chess cribbage)],
        defaults    => [qw(checkers chess)],
        labels      => {checkers=>'Checkers', chess=>'Chess', cribbage=>'Cribbage'},
        disabled    => [qw(chess)],
        linebreak   => 1
    },
    {
        name        => 'game',
        values      => [qw(checkers chess cribbage)],
        attributes  => { chess=> { class=> 'red' }},
    }],

    radio_group  => [{
        name        => 'game',
        values      => [qw(checkers chess cribbage)],
        defaults    => [qw(checkers chess)],
        labels      => {checkers=>'Checkers', chess=>'Chess', cribbage=>'Cribbage'},
        disabled    => [qw(chess)],
        linebreak   => 1
    },
    {
        name        => 'game',
        values      => [qw(checkers chess cribbage)],
        attributes  => { chess=> { class=> 'red' }},
    }],
    
    start_html      => [{
        title       => 'Foobar'
    },
    {
        title      => 'Secrets of the Pyramids',
        author     => 'fred@capricorn.org',                                                                                                                                 
        base       => 'true',                                                                                                                                               
        target     => '_blank',                                                                                                                                             
        meta       => {'keywords'=>'pharaoh secret mummy',
        'copyright' => 'copyright 1996 King Tut'},
        style      => {'src'=>'/styles/style1.css'},
        BGCOLOR    => 'blue'
    }],
    
    scrolling_list  => [{
        name        => 'list_name',
        values      => ['eenie','meenie','minie','moe'],
        default     => ['eenie','moe'],
        multiple    => 'true',
        labels      => {eenie => 'Eenie', meenie => 'Meenie', minie => 'Minie', moe=>'Moe'},
        attributes  => { eenie=> { class=> 'red' } }
    }],

    popup_menu  => [{
        name        => 'list_name',
        values      => ['eenie','meenie','minie','moe'],
        default     => ['eenie','moe'],
        multiple    => 'true',
        labels      => {eenie => 'Eenie', meenie => 'Meenie', minie => 'Minie', moe=>'Moe'},
        attributes  => { eenie=> { class=> 'red' } }
    }]
    
); 


#  Re-impliment CGI input shortcut tags
#
my %tag;
map {$tag{$_}=undef } (grep {!$cgi_ignore{$_}} @{$CGI::EXPORT_TAGS{':form'}}, keys %cgi_test);


# Get rid of stuff we don't wany
#
foreach my $tag (sort keys %tag) {
    if (my $test_ar=$cgi_test{$tag}) {
        foreach my $test_hr (@{$test_ar}) {
            #print Dumper($test_hr);
            #map { printf("%s: %s ($test_hr) $/%s".$/, ref($_), $tag, $_->$tag($test_hr)) } ($c_or, $h_or);
            #die $tag;
            #die $c_or->$tag($test_hr);
            map { printf("%s: %s ($test_hr)$/%s".$/, ref($_), $tag, $_->$tag($test_hr).'') } ($c_or, $h_or);
            print $/;
        }
    }
    else {
        map { printf("%s: %s$/%s".$/, ref($_), $tag, $_->$tag(grep $tag{$tag})).'' } ($c_or, $h_or);
        #map { printf("%s: %s", ref($_), $tag) . $_->$tag(grep $tag{$tag}) .$/.$/ } ($c_or, $h_or);
        print $/;
    }
    #print('FORM:' . $c_or->end_form() . $/)

}


    
