package MIDI_Event;
# MIDI events

use Mouse;
use Modern::Perl;

with 'MIDI_Facilities';

### public

no warnings qw(once);

# ALSA-MIDI event type
sub type {
    my ($self) = @_;
    $self->event_data->[$MIDI_Facilities::TYPE];
}

# ALSA-MIDI event flags
sub flags {
    my ($self) = @_;
    $self->event_data->[$MIDI_Facilities::FLAGS];
}

no warnings qw(once);
# ALSA-MIDI event time stamp
sub time {
    my ($self) = @_;
    $self->event_data->[$MIDI_Facilities::TIME];
}

# ALSA-MIDI event source
sub source {
    my ($self) = @_;
    $self->event_data->[$MIDI_Facilities::SOURCE];
}

# ALSA-MIDI event destination
sub destination {
    my ($self) = @_;
    $self->event_data->[$MIDI_Facilities::DEST];
}

# ALSA-MIDI event data
sub data {
    my ($self) = @_;
    $self->event_data->[$MIDI_Facilities::DATA];
}


# MIDI event components - reference to an array whose contents are the same
# (same order, same meaning) as that documented as the return value of
# MIDI::ALSA::input().  If this parameter is not provided in the
# new/constructor method, it will self-initialize by calling
# MIDI::ALSA::input.
has event_data => (
    is => 'ro',
    isa => 'ArrayRef',
    writer => '_set_event_data',
);

# reference to array of destinations to which the event is to be sent
has destinations => (
    is  => 'ro',
    isa => 'ArrayRef[ArrayRef[Int]]',
);


# Dispatch the event to 'destinations'.
sub dispatch {
    my ($self) = @_;

    my ($type, $flags, $tag, $queue, $time, $source, $destination, $data) =
            @{$self->event_data};
    my $repl_data = $data;
    my $output_source = $destination;
    for my $dest (@{$self->destinations}) {
        output($type, $flags, $tag, $queue, $time, $output_source,
            $dest, $repl_data);
    }
}

### private

# construction helper
sub BUILD {
    my ($self) = @_;
    if (not defined $self->event_data) {
        # 'event_data' was not passed to 'new', so build it here.
        my @event_data = input();
        $self->_set_event_data(\@event_data);
    }
}


1;

