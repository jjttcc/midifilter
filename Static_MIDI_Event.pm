package Static_MIDI_Event;
# MIDI events to be output as is, without modification

use Mouse;
use Modern::Perl;
use Data::Dumper;

extends 'MIDI_Event';

#####  Interface implementation (public)

sub dispatch {
    my ($self) = @_;
    # !!!!This extra method call might be too costly:
    $self->_send_output();
    # !!!Consider "inlining" it.
}

1;

