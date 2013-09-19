package Announcer;
# objects that "announce" a specified message

use Moose;
use Modern::Perl;



sub announce {
    my ($self, $msg) = @_;
    my $cmd = $self->output_program . " '$msg' &";
    system($cmd);
}

sub output_program {
    my ($self) = @_;
    # hard-coded, for now
    'espeak';
}

1;

