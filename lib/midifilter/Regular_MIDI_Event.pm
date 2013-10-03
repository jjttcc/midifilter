package Regular_MIDI_Event;
# "Normal" (i.e., not treated specially) MIDI events to be output to the
# configured MIDI clients (after possible configured modifications)

use Mouse;
use Modern::Perl;
use Data::Dumper;
use MIDI_Facilities;
use constant::boolean;
use feature qw/state/;
use Carp;

extends 'MIDI_Event';

state $debug;

#####  Public interface

# Publisher of status changes with respect to MIDI events (i.e., that this
# object will subscribe to)
has status_change_publisher => (
    is => 'ro',
    isa => 'Object',
);

###  Basic operations

# Utility constant: value indicating that transposition is off for a
# particular pitch
sub TRSP_OFF { -1 }

{
state $transposition_status = [];

# Toggle (on/off) the specified transposition specification.
sub toggle_transposition {
    my ($self, $pitch_value) = @_;
    my $new_value = TRSP_OFF();
    my $spec = $self->config->filter_spec->transposition_specs->{$pitch_value};
    my $first_pitch = $spec->bottom_pitch;
    if ($transposition_status->[$first_pitch] == TRSP_OFF()) {
        # Toggle: OFF to ON, with $pitch_value as a key:
        $new_value = $pitch_value;
    } else {
        # Toggle: ON to OFF:
        $new_value = TRSP_OFF();
    }
    my $last_pitch = $spec->top_pitch;
    my $half_steps = $spec->steps;
    for my $p ($first_pitch .. $last_pitch) {
        $transposition_status->[$p] = $new_value;
    }
    say "tt - tstatus: ", Dumper($transposition_status) if $debug;
}

###  Basic operations

sub dispatch {
    my ($self) = @_;
    # (Optimization: set @destinations only once:)
    state $destinations = $self->config->destination_ports;
    # myself -> source for output calls - not expected to change:
    state $myself = $self->destination();
    state $queue = undef;
    state $time = 0;
    # optimizations
    state $note_on = NOTEON();
    state $note_off = NOTEOFF();
    state $transpositions_configured =
        $self->config->filter_spec->transpositions_configured;
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my ($type, $flags, $tag, undef, undef, undef, undef, $data) =
        @{$self->event_data};
    # If there are configured transpositions and its a note event...
    if ($transpositions_configured and ($type == $note_on or
            $type == $note_off)) {
        my $pitch = $data->[PITCH()];
        if ($transposition_status->[$pitch] != TRSP_OFF()) {
            my $key = $transposition_status->[$pitch];
            state $transpositions =
                $self->config->filter_spec->transposition_specs;
            my $t = $transpositions->{$key};
            $pitch += $t->steps;
            if ($pitch < 0) {
                $pitch = 0;     # Negative pitches don't compute.
            } elsif ($pitch > 127) {
                $pitch = 127;   # Must be within range of MIDI spec.
            }
            $data->[PITCH()] = $pitch;
        }
    }
    for my $dest (@$destinations) {
        # Pass on the received event/message.
        output($type, $flags, $tag, $queue, $time, $myself, $dest, $data);
    }
}


#####  Implementation (non-public)

sub BUILD {
    my ($self) = @_;
    $self->status_change_publisher->subscribe($self);
    for my $pitch (0 .. 127) {
        $transposition_status->[$pitch] = TRSP_OFF();
    }
    $debug = $self->config->debug();
}

}

1;

