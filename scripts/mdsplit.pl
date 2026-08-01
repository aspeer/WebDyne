#  Quick and dirty script to split monolithic markdown file into sections
#
use strict;
use IO::File;
use File::Spec;


#  Run main
#
exit ${&main(\@ARGV) || die 'unknown error'};

# =================================================================================================

sub main {


    #  Get args and extract filename, handle
    #
    my ($fn, $dn)=@{shift()};
    map { $_ || die("usage: $0 <filename> <dn>") }
        ($fn, $dn);
    my $fh=IO::File->new($fn, O_RDONLY) ||
        die("unable to open $fn, $!");


    #  Setup temp vars
    #        
    my @md;         # Array to hold markdown for each section, i.e. md[2]='fff....' is all markdown in section index 2
    my $ix=0;       # Counter of section indexes
    my %section;    # Hash to hold slugified title of each section index
    my $in_code_block=0;  # Flag
    #my @line;       # Temp array of all lines
    
    
    #  Keep track of anchors
    #
    my %anchor;

    
    #  Start reading in markdown file
    #
    my $title;
    while (my $line=<$fh>) {

        #  Don't chomp - need to keep CR's
        #chomp $line;
        
        
        #  Skip unless we have something and are in first section, i.e. skip leading blanks
        #
        unless ($line) { next unless $ix };
        
        
        #  Check for code block marker, if found toggle "in code block" flag. 
        #
        if ($line=~/^```/) {
             $in_code_block^=1;
        }
        
        
        #  If we're not in a code block and we see a section marker we need to split
        #
        if (!$in_code_block && $line=~/^#\s+/) {
            print "section: $line";
            $ix++ if keys %section;
            #my $title=$line;
            $title=$line;
            chomp $title;
            die if $title=~/^#\s*$/;
            $title =~ s/^#+\s*//;                   # Remove leading '#' and whitespace
            $title =~ s/[^A-Za-z0-9]+/_/g;          # Replace non-alphanumeric chars with underscores
            $title =~ s/^_+|_+$//g;                 # Trim leading/trailing underscores
            $title = lc($title); 
            $title = sprintf('%0.2d_%s.md', $ix, $title);
            $section{$ix}=$title;
            
            
        }
        else {
            #  Debugging
            #print "in_code_block: $in_code_block: $line\n";
        }


        #  Look for anchors
        #
        if (!$in_code_block && $line=~/\{#(.*?)\}/) {
            #my $anchor=$1;
            #print "$line, hit $1\n";
            $anchor{$1}=$title;
        }
    

        
        #  Store the current line away against the current section index
        #
        $md[$ix].=$line;

    }


    #  All done on parsing
    #
    print "section discovery complete\n";


    #  Write files out
    #
    while (my($ix, $fn)=each %section) {

        unless (-d $dn) {
            mkdir $dn || die("unable to create output directory $dn, $!");
        }
        my $fn=File::Spec->catfile($dn, $fn);
        my $fh=IO::File->new($fn, O_WRONLY|O_TRUNC|O_CREAT) || 
            die ("unable to write to fn $fn, $!");
            
        #  Update anchors to include file names
        #
        while (my($anchor, $title_fn)=each %anchor) {
        
            #  Search for links and add the file name in before the anchor
            #
            my $escaped_anchor = quotemeta($anchor);
            $md[$ix] =~ s/\[([^\]]+)\]\(\#${escaped_anchor}\)/[$1](${title_fn}#$anchor)/gs;

        }
        print $fh $md[$ix];
        $fh->close();
        print "wrote: $fn\n"
        
    }
    

    #  All done
    #
    return \undef

}
