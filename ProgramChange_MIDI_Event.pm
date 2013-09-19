package ProgramChange_MIDI_Event;
# MIDI events to be (after appropriate self-modification [Currently, assume
# the event data is from a note event and use the pitch as the program
# number.]) output as program change events

use Mouse;
use Modern::Perl;
use Data::Dumper;
use MIDI_Facilities;
use Announcer;
use GeneralMidi;

extends 'MIDI_Event';


#####  Interface implementation (public)


sub dispatch {
    my ($self) = @_;
    state $destinations = $self->config->destination_ports;
    # myself -> source for output calls - not expected to change:
    state $myself = $self->destination();
    state $queue = undef;
    state $time = 0;
    state $pc = PGMCHANGE();
    state $announcer = Announcer->new();
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my (undef, $flags, $tag,  undef, undef, undef, undef, $data) =
        @{$self->event_data};
    my ($channel, $pitch) = @$data;
    # ($pitch becomes an alias for program/patch number.)

    my $instrument = $instrument_name_for->{$pitch};
    $announcer->announce("Patch $pitch: $instrument");
    for my $dest (@{$destinations}) {
        output(PGMCHANGE(), $flags, $tag, $queue, $time, $myself, $dest,
            [$channel, 0, 0, 0, 0, $pitch]);
    }
}


1;
