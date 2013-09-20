package Announcer;
# objects that "announce" a specified message

use Mouse;
use Modern::Perl;
use Data::Dumper;
use Carp;


#####  Public interface

###  Access

has announce_prog => (
    is => 'rw',
    isa => 'Str',
);

###  Basic operations

# "Announce" $msg.
sub announce {
    my ($self, $msg) = @_;
    my $cmd = $self->announce_prog . " '$msg' &";
    system($cmd);
}


1;

