package MIDI_Facilities;
# MIDI-related constants, utilities, etc.

use Filter::Macro;  # 'use MIDI_Facilities' provides inline expansion.
use Modern::Perl;

use Music::Note;
use MIDI::ALSA qw(
    SND_SEQ_EVENT_PORT_UNSUBSCRIBED
    SND_SEQ_EVENT_NOTE
    SND_SEQ_EVENT_NOTEON
    SND_SEQ_EVENT_NOTEOFF
    SND_SEQ_EVENT_PGMCHANGE
    SND_SEQ_EVENT_CONTROLLER
    SND_SEQ_EVENT_START
    SND_SEQ_EVENT_STOP
    SND_SEQ_EVENT_CONTINUE
    input
    output
    connectto
    connectfrom
    pgmchangeevent
    controllerevent
);


###  Constants

# Convenience constants for important MIDI event types for state transition
sub NOTEON()     { SND_SEQ_EVENT_NOTEON()     }
sub NOTEOFF()    { SND_SEQ_EVENT_NOTEOFF()    }
sub CONTROLLER() { SND_SEQ_EVENT_CONTROLLER() }
sub PGMCHANGE()  { SND_SEQ_EVENT_PGMCHANGE()  }
sub START()      { SND_SEQ_EVENT_START()      } # MIDI real time start message
sub STOP()       { SND_SEQ_EVENT_STOP()       } # MIDI real time stop message
sub CONTINUE()   { SND_SEQ_EVENT_CONTINUE()   } # MIDI Real time continue msg

# parameter/sub-message types, MIDI pitches, etc.
sub BANKMSB_SELECT()      { 0 }
sub BANKLSB_SELECT()      { 32 }
sub CHANNEL_VOLUME()      { 7 }

# (Assumption: 88-key keyboard)
sub LOWEST_88KEY_PITCH()  { 21  }  # Bottom note on keyboard
sub HIGHEST_88KEY_PITCH() { 108 }  # Top note on keyboard

# ALSA MIDI event-data components - array position
sub TYPE()   { 0 }
sub FLAGS()  { 1 }
sub TAG()    { 2 }
sub QUEUE()  { 3 }
sub TIME()   { 4 }
sub SOURCE() { 5 }
sub DEST()   { 6 }
sub DATA()   { 7 }

# ALSA MIDI MIDI-data NOTE-ON/NOTE-OFF components - array position
sub PITCH()    { 1 }     # (channel is 0 - see below)
sub VELOCITY() { 2 }
sub DURATION() { 4 }  # Note: position 3 is unused.
# ALSA MIDI MIDI-data generic event (non-note-event) components - array position
sub CHANNEL()  { 0 }
sub PARAM()    { 4 } # Note: positions 1, 2, 3 are unused.
sub VALUE()    { 5 }

# Event-filtering processing states
sub NORMAL()         { 0 } # Next event to be output as is
sub OVERRIDE()       { 1 } # Command override state
sub PROGRAM_CHANGE() { 2 } # Program change to be sent
sub BANK_SELECT()    { 3 } # Bank select to be sent
sub EXTERNAL_CMD()   { 4 } # External command to be executed
sub REALTIME()       { 5 } # MIDI real-time message to be sent

# Special constants
sub TERMINATE_CMD() { '<terminate>' } # Request for program termination


1;
