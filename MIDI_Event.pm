package MIDI_Event;
# Self-dispatching ALSA-MIDI events, dispatched according to the class type
# (subtype)

use Mouse;
use Modern::Perl;
use Carp;

with 'MIDI_Facilities';

### public

no warnings qw(once);

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

no warnings qw(once);
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

# reference to array of destinations to which the event is to be sent
has destinations => (
    is  => 'ro',
    isa => 'ArrayRef[ArrayRef[Int]]',
);


# Dispatch the event to 'destinations'.
sub dispatch {
    my ($self) = @_;

    die "abstract method needs to be implemented in ", ref $self;
=cut=
###### !!!!!!obsolete
    my ($type, $flags, $tag, $queue, $time, $source, $destination, $data) =
            @{$self->event_data};
    my $repl_data = $data;
    my $output_source = $destination;
    for my $dest (@{$self->destinations}) {
        output($type, $flags, $tag, $queue, $time, $output_source,
            $dest, $repl_data);
    }
=cut=
}

### private

sub BUILD {
    my ($self) = @_;

    if (ref $self eq 'MIDI_Event') {
        confess "Instantiation of abstract class [" . $self . "]";
    }
say "I've been built! [", ref $self, ']';
}

# construction helper
sub old_BUILD {
    my ($self) = @_;
    if (not defined $self->event_data) {
        # 'event_data' was not passed to 'new', so build it here.
        my @event_data = input();
        $self->set_event_data(\@event_data);
    }
}


1;

