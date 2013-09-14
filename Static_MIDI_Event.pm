package Static_MIDI_Event;
# MIDI events to be output as is, without modification

use Mouse;
use Modern::Perl;
use Data::Dumper;

extends 'MIDI_Event';

#####  Interface implementation (public)

sub dispatch {
    my ($self) = @_;
if ($self->type == 42) { return; }  #!!!!!
say ref $self, "::dispatch called - self:", Dumper($self);
say "type: ", $self->type;
say "dests: ", Dumper($self->destinations);
# !!!!dummy - needs implementation
    $self->_send_output();
}

1;

