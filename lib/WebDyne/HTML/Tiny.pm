#
#  This file is part of WebDyne.
#
#  This software is Copyright (c) 2024 by Andrew Speer <andrew@webdyne.org>.
#
#  This is free software, licensed under:
#
#    The GNU General Public License, Version 2, June 1991
#
#  Full license text is available at:
#
#  <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>
#
package WebDyne::HTML::Tiny;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION);
use warnings;


#  Constants, inheritance
#
our $AUTOLOAD;
our @ISA=qw(HTML::Tiny);


#  External Modules
#
use HTML::Tiny;
use URI::Escape;
use Data::Dumper;


#  WebDyne Modules
#
use WebDyne::Constant;
use WebDyne::Base;


#  Constants
#
use constant {

    URL_ENCODED     => 'application/x-www-form-urlencoded',
    MULTIPART       => 'multipart/form-data'

};


#  Version information
#
$VERSION='1.251';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  All done. Positive return
#
return ${&init()} || err('error running init code');


#==================================================================================================

sub init {

    #  Initialise various subs
    #
    *HTML::Tiny::start=\&HTML::Tiny::open || *HTML::Tiny::start; # || *HTML::Tiny::Start stops warning
    *HTML::Tiny::end=\&HTML::Tiny::close  || *HTML::Tiny::end; # || as above
    

    #  Re-impliment CGI input shortcut tags
    #
    foreach my $tag (qw(textfield password_field filefield button submit reset defaults image_button hidden)) {

        my %type=(
            textfield       => 'text',
            password_field  => 'password',
            filefield       => 'file',
            defaults        => 'submit',
            image_button    => 'image'
        );

        *{$tag}=sub { 
            my ($s, $attr_hr)=(shift(),shift());
            if ($attr_hr) {
                return $s->input({ type=>$type{$tag} || $tag, %{$attr_hr} }, @_);
            }
            else {
                return $s->input({ type=>$type{$tag} || $tag }, @_)
            };

        };
        
    }


    #  Isindex deprecated but reimplement anyway
    #
    foreach my $tag (qw(isindex)) {

        no strict qw(refs);
        *{$tag}=sub { shift()->closed($tag, @_) };
        
    }

    
    #  Done return OK
    #
    return \1;

}    
    

sub AUTOLOAD {
    print "AUTOLOAD: $AUTOLOAD\n";
    if (my ($action, $tag) = ($AUTOLOAD =~ /\:\:(start|end)_([^:]+)$/)) {
        *{$AUTOLOAD}=sub { shift()->$action($tag, @_) };
        return &{$AUTOLOAD}(@_);
    }
}


#  Start_html shorcut and include DTD
#
sub start_html {

    my ($self, $attr_hr)=@_;
    keys %{$attr_hr} || ($attr_hr=$WEBDYNE_HTML_PARAM);
    my %attr_page=map {$_=>delete $attr_hr->{$_}} qw(
        title
        meta
        style
        base
        target
        author
    );

    my @html=$WEBDYNE_DTD;
    my @meta;
    while (my ($name, $content)=each %{$attr_page{'meta'}}) {
        push @meta, $self->meta({ name=>$name, content=>$content });
    }
    my @link;
    while (my ($src, $href)=each %{$attr_page{'style'}}) {
        push @link, $self->link({ rel=>'stylesheet', href=>$href });
    }
    if (my $author=$attr_page{'author'}) {
        $author=uri_escape($author);
        push @link, $self->link({ rel=>'author', href=>sprintf('mailto:%s', $author) });
    }
    my $head=$self->head(join($/,
        grep {$_}
        $self->title($attr_page{'title'} || 'Untitled Document'),
        @meta,
        @link
    ));
    
    push @html, $self->open('html', $attr_hr), $head;
    return join($/, @html);
    
}


#  Big shortcut, creates page in one hit
#
sub html {

    my ($self, $attr_hr, @html)=@_;
    return join('', $self->start_html($attr_hr), @html, $self->end_html);

}

#  Start_form shortcut
#
sub start_form {

    my ($s, $attr_hr, @param)=@_;
    my %default=(
        method  => 'post',
        enctype => +URL_ENCODED
    );
    map { $attr_hr->{$_} ||= $default{$_} }
        keys %default;
    return $s->start('form', $attr_hr, @param);
}



#  Start multi-part form shortcut
#
sub start_multipart_form {
    return shift()->start_form({ enctype=>+MULTIPART, %{shift()} }, @_);
}


sub end_multipart_form {
    return shift()->end_form(@_);
}


#  Support CGI comment syntax
#
sub comment {
    
    my $s=shift();
    return sprintf('<!-- '.shift().' -->', @_);
    
}


sub _radio_checkbox {


    #  Return a radio or checkboxinput field, adding label tags if needed
    #
    my ($self, $tag, $attr_hr)=@_;
    if (my $label=delete $attr_hr->{'label'}) {
        return $self->label($self->input({ type=>$tag, %{$attr_hr} }) . $label);
    }
    else {
        return $self->input({ type=>$tag, %{$attr_hr} });
    }
    
}


#  Checkbox group
#
sub _radio_checkbox_group {


    #  Build a checkbox or radio group
    #
    my ($self, $tag, $attr_hr)=@_;
    

    #  Hold generated HTML in array until end
    #
    my @html;
    
    
    #  Convert arrays of default values (i.e checked/enabled) and any disabled entries into hash - easier to check
    #
    my %attr_group;
    foreach my $attr (qw(defaults disabled)) {
        map { $attr_group{$attr}{$_}=1 } @{(ref($attr_hr->{$attr}) eq 'ARRAY') ? $attr_hr->{$attr} : [$attr_hr->{$attr}] }
            if $attr_hr->{$attr};
    }
    
    
    #  Radio groups can only have one option checked. If multiple discard and only use first one in alphabetical order
    #
    if ($tag eq 'radio') {
        %{$attr_group{'defaults'}}=map {$_=>$attr_group{'defaults'}{$_}} ([sort keys %{$attr_group{'defaults'}}]->[0])
            if $attr_group{'defaults'};
    }
    
    
    #  Now iterate and build actual tag, push onto HTML array
    #
    foreach my $value (@{$attr_hr->{'values'}}) {
        my %attr_tag = $attr_hr->{'attributes'}{$value} ?
            (%{ $attr_hr->{'attributes'}{$value} }) :
            ();
        $attr_tag{'name'}=$attr_hr->{'name'} if $attr_hr->{'name'};
        
        #  Note use of empty array for checked and disabled values as per HTML::Tiny specs
        $attr_tag{'checked'}=[] if $attr_group{'defaults'}{$value};
        $attr_tag{'disabled'}=[] if $attr_group{'disabled'}{$value};
        $attr_tag{'label'}=$attr_hr->{'labels'}{$value} if $attr_hr->{'labels'}{$value};
        push @html, $self->_radio_checkbox($tag, \%attr_tag);
    }
    
    
    #  Return, separating with linebreaks if that is what is wanted.
    #
    return join($attr_hr->{'linebreak'} ? $self->br() : '', @html); 
    
}

sub checkbox_group {
    return shift()->_radio_checkbox_group('checkbox', @_)
}    

sub radio_group {
    return shift()->_radio_checkbox_group('radio', @_)
}    

sub checkbox {
    return shift()->_radio_checkbox('checkbox', @_)
}    


#  Popup menu or scrolling list
#
sub popup_menu {


    #  Build a checkbox or radio group
    #
    my ($self, $attr_hr)=@_;
    my %attr=%{$attr_hr};
    

    #  Hold generated HTML in array until end
    #
    my @html;
    
    
    #  Convert arrays of default values (i.e checked/enabled) and any disabled entries into hash - easier to check
    #
    my %attr_group=(
        values		=> delete $attr{'values'},
        attributes	=> delete $attr{'attributes'},
        labels		=> delete $attr{'labels'}
    );	
    foreach my $attr (qw(default selected disabled)) {
        map { $attr_group{$attr}{$_}=1 } @{(ref($attr{$attr}) eq 'ARRAY') ? $attr{$attr} : [$attr{$attr}] }
            if $attr{$attr};
        delete $attr{$attr};
    }
    
    
    #  Convert 'defaults' key to 'selected'
    #
    do { $attr_group{'selected'} ||= delete $attr_group{'defaults'} }
        if $attr_group{'defaults'};
    
    
    #  If disabled option is an array but is empty then it is meant for the parent tag
    #
    if ($attr_group{'disabled'} && !@{$attr_group{'disabled'}}) {
    
        #  Yes, it is empty, so user wants whole option disabled
        #
        $attr{'disabled'}=[]

    }
    
    
    #  Fix multiple tag if true
    #
    $attr{'multiple'}=[] if $attr{'multiple'};
        
    
    #  Now iterate and build actual tag, push onto HTML array
    #
    foreach my $value (@{$attr_group{'values'}}) {
        my %attr_tag = $attr_group{'attributes'}{$value} ?
            (%{ $attr_group{'attributes'}{$value} }) :
            ();
        $attr_tag{'value'}=$value;
        
        #  Note use of empty array for checked and disabled values as per HTML::Tiny specs
        $attr_tag{'selected'}=[] if $attr_group{'selected'}{$value};
        $attr_tag{'disabled'}=[] if $attr_group{'disabled'}{$value};
        my $label=$attr_group{'labels'}{$value} if $attr_group{'labels'}{$value};
        if ($label) {
            push @html, $self->label($self->option(\%attr_tag) . $label);
        }
        else {
            push @html, $self->option(\%attr_tag)
        }
    }
    
    
    #  Return
    #
    return $self->select(\%attr, join($/, @html)); 
    
}


sub scrolling_list {

    #  Only difference between popup_menu and scrolling list is size attrribute, which we calculate  -if
    #  supplied will overwrite calculated value
    #
    return shift()->popup_menu({ size=>scalar @{$_[0]->{'values'}}, %{shift()}}, @_);
    
}


sub AUTOLOAD {
    if (my ($action, $tag) = ($AUTOLOAD =~ /\:\:(start|end)_([^:]+)$/)) {
        *{$AUTOLOAD}=sub { shift()->$action($tag, @_) };
        return &{$AUTOLOAD}(@_);
    }
}
