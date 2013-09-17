package MIDI_Event;
# Self-dispatching ALSA-MIDI events, dispatched according to the class type
# (subtype)

use Mouse;
use Modern::Perl;
use Carp;
use feature 'state';
use Data::Dumper;

use MIDI_Facilities;

#####  Public interface

# event type
sub type {
    my ($self) = @_;
    $self->event_data->[TYPE()];
}

# event flags
sub flags {
    my ($self) = @_;
    $self->event_data->[FLAGS()];
}

no warnings qw(once);   #!!!!!
# event time stamp
sub time {
    my ($self) = @_;
    $self->event_data->[TIME()];
}

# event source
sub source {
    my ($self) = @_;
    $self->event_data->[SOURCE()];
}

# event destination
sub destination {
    my ($self) = @_;
    $self->event_data->[DEST()];
}

# MIDI-specific data
sub data {
    my ($self) = @_;
    $self->event_data->[DATA()];
}

# MIDI event components - reference to an array whose contents are the same
# (same order, same meaning) as that documented as the return value of
# MIDI::ALSA::input().  If this parameter is not provided in the
# new/constructor method, it will self-initialize by calling
# MIDI::ALSA::input.
has event_data => (
    is => 'rw',
    isa => 'ArrayRef',
);

has config => (
    is  => 'ro',
    isa => 'MIDI_Configuration',
);

# Dispatch the event to 'destinations'.
sub dispatch {
    my ($self) = @_;

    die "abstract method needs to be implemented in ", ref $self;
}

#####  Implementation

sub BUILD {
    my ($self) = @_;

    if (ref $self eq 'MIDI_Event') {
        confess "Instantiation of abstract class [" . $self . "]";
    }
say "I've been built! [", ref $self, ']';
}

# Send 'event_data', as is, to 'destinations'.
sub _send_output {
    my ($self) = @_;
say "MIDI_Event::_send_output [for ", ref $self, "]: self: ", Dumper($self);
    # (Optimization: set @destinations only once:)
    state $destinations = $self->config->destination_ports;
    # myself -> source for output calls - not expected to change:
    state $myself = $self->destination();
    state $queue = undef;
    state $time = 0;
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my ($type, $flags, $tag, undef, undef, undef, undef, $data) =
        @{$self->event_data};
#if (defined $data->[PITCH()] and $data->[PITCH()] == 21) { #!!!!
#exit $data->[PITCH()]; } #!!!!!!
    for my $dest (@$destinations) {
        # Pass on the received event/message.
        output($type, $flags, $tag, $queue, $time, $myself, $dest, $data);
    }
}
1;

