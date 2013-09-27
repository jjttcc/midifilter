package Static_MIDI_Event;
# MIDI events to be output as is, without modification [!!!!to-do: redo this
# description - account for transpositions, ...!!!]
# !!!!to-do: [perhaps] rename the class to indicate filtering can occur

use Mouse;
use Modern::Perl;
use Data::Dumper;
use MIDI_Facilities;
use constant::boolean;
use Carp;

extends 'MIDI_Event';


#####  Public interface

{
state $transpositions = {};

# Toggle (on/off) the specified transposition specification.
sub toggle_transposition {
    my ($self, $pitch_value) = @_;
    my $configured_trs = $self->config->filter_spec->transposition_specs;
    my $trans = $transpositions->{$pitch_value};
    if (not defined $trans) {
        my $tr_spec = $configured_trs->{$pitch_value};
        if (not defined $tr_spec) {
            croak "Fatal error: code defect [line ", __LINE__,
                ", file ", __FILE__, "]";
        }
        $trans->{$pitch_value} = [$tr_spec, TRUE];
    } else {
        my $trans_spec = $trans->{$pitch_value};
        $trans_spec->[1] = not $trans_spec->[1];    # [toggle]
    }
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
    state $transpositions_pending =
        $self->config->filter_spec->transpositions_pending;
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my ($type, $flags, $tag, undef, undef, undef, undef, $data) =
        @{$self->event_data};
#say STDERR "tsp: ", $transpositions_pending;
#say STDERR "type: ", $type;
#say STDERR "note on: ", $note_on;
#say STDERR "note off: ", $note_off;
    if ($transpositions_pending and ($type == $note_on or
            $type == $note_off)) {
        state $transpositions = $self->config->filter_spec->transposition_specs;
        my $pitch = $data->[PITCH()];
        for my $t (values %{$transpositions}) {
            if ($pitch >= $t->bottom_pitch and $pitch <= $t->top_pitch) {
#say STDERR "old PITCH: ", $pitch;
                $pitch += $t->steps;
                if ($pitch < 0) {
                    $pitch = 0;     # Negative pitches don't compute.
                } elsif ($pitch > 127) {
                    $pitch = 127;   # Must be within range of MIDI spec.
                }
#say STDERR "new pitch: ", $pitch;
                $data->[PITCH()] = $pitch;
                last;
            }
        }
    }
    for my $dest (@$destinations) {
        # Pass on the received event/message.
        output($type, $flags, $tag, $queue, $time, $myself, $dest, $data);
    }
}

}

1;

