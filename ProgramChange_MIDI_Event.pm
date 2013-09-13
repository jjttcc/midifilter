package ProgramChange_MIDI_Event;
# MIDI events to be (after appropriate self-modification) output as
# program change events

use Mouse;
use Modern::Perl;

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

