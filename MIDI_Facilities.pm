package MIDI_Facilities;
# MIDI-related constants, utilities, etc.

use Mouse::Role;
use Modern::Perl;
use Readonly;

use Music::Note;
use MIDI::ALSA qw(
    SND_SEQ_EVENT_PORT_UNSUBSCRIBED
    SND_SEQ_EVENT_NOTE
    SND_SEQ_EVENT_NOTEON
    SND_SEQ_EVENT_NOTEOFF
    SND_SEQ_EVENT_PGMCHANGE
    SND_SEQ_EVENT_CONTROLLER
    input
    output
    connectto
    connectfrom
    pgmchangeevent
    controllerevent
);


###  Constants

# Convenience constants for important MIDI event types for state transition
sub NOTEON() { SND_SEQ_EVENT_NOTEON }
sub NOTEOFF() { SND_SEQ_EVENT_NOTEOFF }
sub CONTROLLER() { SND_SEQ_EVENT_CONTROLLER }

# Constants: parameter/sub-message types, MIDI pitches, etc.
sub BANKMSB_SELECT() { 0 }
sub BANKLSB_SELECT() { 32 }
sub CHANNEL_VOLUME() { 7 }
sub C8() { 108 }
sub B7() { 107 }
sub Bb7() { 106 }
sub A7() { 105 }
# lowest MIDI pitch value used for event override control:
sub CTL_START() { A7() }
sub LOWEST_88KEY_PITCH() { 21 }     # Bottom A on keyboard
sub HIGHEST_88KEY_PITCH() { 108 }   # Top C on keyboard

# Constants: ALSA MIDI event-data components - array position
sub TYPE() { 0 }
sub FLAGS() { 1 }
sub TAG() { 2 }
sub QUEUE() { 3 }
sub TIME() { 4 }
sub SOURCE() { 5 }
sub DEST() { 6 }
sub DATA() { 7 }


1;

