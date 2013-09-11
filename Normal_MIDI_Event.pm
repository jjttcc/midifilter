package Normal_MIDI_Event;
# MIDI events to be handled normally

use Mouse;
use Modern::Perl;

extends 'MIDI_Event';

sub dispatch {
    my ($self) = @_;
say "Normal_MIDI_Event::dispatch called";
exit 91;
}

1;

