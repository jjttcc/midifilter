package Normal_MIDI_Event;
# MIDI events to be handled normally - i.e., output without modification

use Mouse;
use Modern::Perl;
use Data::Dumper;

extends 'MIDI_Event';

#####  Interface implementation (public)

sub dispatch {
    my ($self) = @_;
say ref $self, "::dispatch called - self:", Dumper($self);
say "dests: ", Dumper($self->destinations);
# !!!!dummy - needs implementation
    $self->_send_output();
}

1;

