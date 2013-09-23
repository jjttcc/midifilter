package Announcer;
# objects that "announce" a specified message

use Mouse;
use Modern::Perl;
use constant::boolean;
use feature qw/state/;
use File::Temp qw/:mktemp/;
use Data::Dumper;
use Carp;


#####  Public interface

###  Access

has announce_prog => (
    is       => 'rw',
    isa      => 'Str',
    required => TRUE,
);

###  Basic operations

state $tmpfile;

# "Announce" $msg.
sub announce {
    my ($self, $msg) = @_;
    if (not defined $tmpfile) {
        $tmpfile = File::Temp->new(TEMPLATE => "ann{$$}XXXXX", DIR => '/tmp/',
            UNLINK => 0);
    } else {
        unlink $tmpfile;
        $tmpfile = File::Temp->new(TEMPLATE => "ann{$$}XXXXX", DIR => '/tmp/',
            UNLINK => 0);
    }
    $tmpfile->write($msg);
    $tmpfile->flush();
    my $cmd = $self->announce_prog . ' <' . $tmpfile->filename . ' &';
    system($cmd);
}


#####  Implementation (non-public)

END {
    unlink $tmpfile;
}

1;

