package ReleaseDemo;

use strict;
use warnings;

use Fcntl qw(:flock);
use File::Spec;
use File::Temp qw(tempfile);
use JSON ();


my $state_dn='/tmp';
my @STAGE=(
    'Ready to start',
    'Building application',
    'Running checks',
    'Deploying release',
    'Release live',
);


sub status {

    my $self=shift();
    my $state_hr=state();
    my $stage_ix=$state_hr->{'stage_ix'};
    my $live=($stage_ix == $#STAGE) ? 'live' : '';
    my $action_label=$live ? 'Start again' : 'Advance release';

    return $self->render(
        action_label => $action_label,
        changed_at   => $state_hr->{'changed_at'},
        live         => $live,
        revision     => $state_hr->{'revision'},
        stage        => $STAGE[$stage_ix],
    );
}


sub action {

    my $self=shift();
    my $action=scalar($self->CGI()->param('action')) || '';

    unless ($action eq 'advance') {
        return $self->err("unknown release demo action '$action'");
    }
    advance();

    # Return the updated fragment to the initiating viewer. SSE refreshes
    # other open viewers through the same status endpoint.
    return status($self);
}


sub fingerprint {

    my $state_hr=state();
    return $state_hr->{'revision'};
}


sub state {

    my $lock_fh=lock_fh();
    my $state_hr=read_state();
    close($lock_fh);
    return $state_hr;
}


sub advance {

    my $lock_fh=lock_fh();
    my $state_hr=read_state();
    $state_hr->{'stage_ix'}=($state_hr->{'stage_ix'} == $#STAGE)
        ? 0
        : $state_hr->{'stage_ix'} + 1;
    write_state($state_hr);
    close($lock_fh);
    return $state_hr;
}


sub lock_fh {

    open(my $lock_fh, '>>', lock_fn()) ||
        die "unable to open release demo lock file: $!";
    flock($lock_fh, LOCK_EX) ||
        die "unable to lock release demo state: $!";
    return $lock_fh;
}


sub read_state {

    my $state_hr={
        changed_at => scalar(localtime()),
        revision   => 0,
        stage_ix   => 0,
    };
    return $state_hr unless -f state_fn();

    open(my $state_fh, '<', state_fn()) ||
        die "unable to open release demo state: $!";
    local $/;
    my $json=<$state_fh>;
    close($state_fh);

    my $stored_hr=eval {JSON->new()->decode($json)} || {};
    foreach my $key (qw(changed_at revision stage_ix)) {
        $state_hr->{$key}=$stored_hr->{$key}
            if exists($stored_hr->{$key});
    }
    $state_hr->{'stage_ix'}=0
        unless $state_hr->{'stage_ix'} =~ /\A\d+\z/ &&
            $state_hr->{'stage_ix'} <= $#STAGE;
    return $state_hr;
}


sub write_state {

    my $state_hr=shift();
    $state_hr->{'changed_at'}=scalar(localtime());
    $state_hr->{'revision'}++;

    my ($state_fh, $temp_fn)=tempfile(
        'webdyne-release-demo-XXXXXX',
        DIR    => $state_dn,
        UNLINK => 0,
    );
    print {$state_fh} JSON->new()->canonical()->encode($state_hr);
    $state_fh->close() ||
        die "unable to close release demo state: $!";
    rename($temp_fn, state_fn()) ||
        die "unable to replace release demo state: $!";
    return $state_hr;
}


sub state_fn {

    return File::Spec->catfile($state_dn, 'webdyne-release-demo.json');
}


sub lock_fn {

    return File::Spec->catfile($state_dn, 'webdyne-release-demo.lock');
}


1;
