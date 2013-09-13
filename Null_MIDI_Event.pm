package Null_MIDI_Event;
# No-op MIDI events - i.e., dispatch does nothing

use Mouse;
use Modern::Perl;

extends 'MIDI_Event';

sub dispatch { }

1;

