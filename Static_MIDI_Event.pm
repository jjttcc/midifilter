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

###  Access

# !!!!!!to-do: Make this non-public!!!
has status_change_publisher => (
    is => 'ro',
    isa => 'Object',
);

###  Basic operations

{
state $transposition_enabled = {};

# Toggle (on/off) the specified transposition specification.
sub toggle_transposition {
    my ($self, $pitch_value) = @_;
    my $new_state = FALSE;
say "toggle_transposition called with pitch $pitch_value";
my $spec = $self->config->filter_spec->transposition_specs->{$pitch_value};
say "spec: ", Dumper($spec);
    my $first_pitch = $spec->bottom_pitch;
    if (not $transposition_enabled->{$first_pitch}) {
        $new_state = TRUE;
    }
    my $last_pitch = $spec->top_pitch;
    my $half_steps = $spec->steps;
    for my $p ($first_pitch .. $last_pitch) {
        $transposition_enabled->{$p} = $new_state;
    }
say "tt - ten: ", Dumper($transposition_enabled);
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
        if ($transposition_enabled->{$pitch}) {
            state $transpositions =
                $self->config->filter_spec->transposition_specs;
            for my $t (values %{$transpositions}) {
                if ($pitch >= $t->bottom_pitch and $pitch <= $t->top_pitch) {
say STDERR "old PITCH: ", $pitch;
                    $pitch += $t->steps;
                    if ($pitch < 0) {
                        $pitch = 0;     # Negative pitches don't compute.
                    } elsif ($pitch > 127) {
                        $pitch = 127;   # Must be within range of MIDI spec.
                    }
say STDERR "new pitch: ", $pitch;
                    $data->[PITCH()] = $pitch;
                    last;
                }
            }
        }
    }
    for my $dest (@$destinations) {
        # Pass on the received event/message.
        output($type, $flags, $tag, $queue, $time, $myself, $dest, $data);
    }
}

}


#####  Implementation (non-public)

sub BUILD {
    my ($self) = @_;
    $self->status_change_publisher->subscribe($self);
}

1;

