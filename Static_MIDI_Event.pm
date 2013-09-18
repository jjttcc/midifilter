package Static_MIDI_Event;
# MIDI events to be output as is, without modification

use Mouse;
use Modern::Perl;
use Data::Dumper;
use MIDI_Facilities;

extends 'MIDI_Event';

#####  Interface implementation (public)

sub dispatch {
    my ($self) = @_;
    # (Optimization: set @destinations only once:)
    state $destinations = $self->config->destination_ports;
    # myself -> source for output calls - not expected to change:
    state $myself = $self->destination();
    state $queue = undef;
    state $time = 0;
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my ($type, $flags, $tag, undef, undef, undef, undef, $data) =
        @{$self->event_data};
    for my $dest (@$destinations) {
        # Pass on the received event/message.
        output($type, $flags, $tag, $queue, $time, $myself, $dest, $data);
    }
}

1;

