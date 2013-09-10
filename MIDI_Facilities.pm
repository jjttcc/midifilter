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


# Constants: parameter/sub-message types, MIDI pitches, etc.
Readonly::Scalar our $BANKMSB_SELECT        => 0;
Readonly::Scalar our $BANKLSB_SELECT        => 32;
Readonly::Scalar our $CHANNEL_VOLUME        => 7;
Readonly::Scalar our $C8                    => 108;
Readonly::Scalar our $B7                    => 107;
Readonly::Scalar our $Bb7                   => 106;
Readonly::Scalar our $A7                    => 105;
# lowest MIDI pitch value used for event override control:
Readonly::Scalar our $CTL_START             => $A7;
Readonly::Scalar our $LOWEST_88KEY_PITCH    => 21;  # Bottom A on keyboard
Readonly::Scalar our $HIGHEST_88KEY_PITCH   => 108; # Top C on keyboard

# Constants: ALSA MIDI event-data components - array position
Readonly::Scalar our $TYPE   => 0;
Readonly::Scalar our $FLAGS  => 1;
Readonly::Scalar our $TAG    => 2;
Readonly::Scalar our $QUEUE  => 3;
Readonly::Scalar our $TIME   => 4;
Readonly::Scalar our $SOURCE => 5;
Readonly::Scalar our $DEST   => 6;
Readonly::Scalar our $DATA   => 7;


1;

