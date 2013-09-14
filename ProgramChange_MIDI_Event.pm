package ProgramChange_MIDI_Event;
# MIDI events to be (after appropriate self-modification [Currently, assume
# the event data is from a note event and use the pitch as the program
# number.]) output as program change events

use Mouse;
use Modern::Perl;
use Data::Dumper;
use MIDI_Facilities;

extends 'MIDI_Event';


#####  Interface implementation (public)


sub dispatch {
    my ($self) = @_;
say ref $self, "::dispatch called - self:", Dumper($self);
    state $destinations = $self->destinations;
    # myself -> source for output calls - not expected to change:
    state $myself = $self->destination();
    state $queue = undef;
    state $time = 0;
    state $pc = PGMCHANGE();
# (Assume: queue, time, source, destination [undefs] are not needed:)
    my (undef, $flags, $tag,  undef, undef, undef, undef, $data) =
        @{$self->event_data};
say "data: ", Dumper($data);
    my ($channel, $pitch) = @$data;
    # ($pitch becomes an alias for program/patch number.)
say "pitch: $pitch";

    for my $dest (@{$destinations}) {
say('sending program change', $myself, $dest, $data);
        output(PGMCHANGE(), $flags, $tag, $queue, $time, $myself, $dest,
            [$channel, 0, 0, 0, 0, $pitch]);
    }
#  Change the event type to program change; change the program number
#  to the pitch value ...

say "dests: ", Dumper($self->destinations);
}


1;
