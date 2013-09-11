package MIDI_EventDispatcher;
# MIDI event dispatching functionality, based on event type/criteria

use Mouse;

has event => (
    is      => 'ro',
    # !!!!Maybe allows undef - check if it works after new():
    isa     => 'Maybe[MIDI_Event]',
);


sub BUILD {
    my ($self) = @_;
    die "Instantiation of abstract class [" . $self . "]";
}

1;

