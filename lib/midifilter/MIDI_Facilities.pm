package MIDI_Facilities;
# MIDI-related constants, utilities, etc.

use Filter::Macro;  # 'use MIDI_Facilities' provides inline expansion.
use Modern::Perl;
use feature 'state';

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
    SND_SEQ_EVENT_SYSEX
    input
    output
    connectto
    connectfrom
    pgmchangeevent
    controllerevent
);

use MIDI_Configuration;

###   Constants

state $DEBUG = MIDI_Configuration::debug(); # cached debug status


##  Convenience constants for important MIDI event types for state transition
sub NOTEON()     { SND_SEQ_EVENT_NOTEON()     }
sub NOTEOFF()    { SND_SEQ_EVENT_NOTEOFF()    }
sub CONTROLLER() { SND_SEQ_EVENT_CONTROLLER() }
sub PGMCHANGE()  { SND_SEQ_EVENT_PGMCHANGE()  }
sub START()      { SND_SEQ_EVENT_START()      } # MIDI real time start message
sub STOP()       { SND_SEQ_EVENT_STOP()       } # MIDI real time stop message
sub CONTINUE()   { SND_SEQ_EVENT_CONTINUE()   } # MIDI Real time continue msg
sub SYSEX()      { SND_SEQ_EVENT_SYSEX()      } # system exclusive message

##  parameter/sub-message types, MIDI controller values, etc.
sub BANKMSB_SELECT()      { 0 }
sub BANKLSB_SELECT()      { 32 }
sub CHANNEL_VOLUME()      { 7 }

##  ALSA MIDI event-data components - array position
sub TYPE()   { 0 }
sub FLAGS()  { 1 }
sub TAG()    { 2 }
sub QUEUE()  { 3 }
sub TIME()   { 4 }
sub SOURCE() { 5 }
sub DEST()   { 6 }
sub DATA()   { 7 }

##  ALSA MIDI MIDI-data NOTE-ON/NOTE-OFF components - array position
sub PITCH()    { 1 }     # (channel is 0 - see below)
sub VELOCITY() { 2 }
sub DURATION() { 4 }  # Note: position 3 is unused.
##  ALSA MIDI-data generic event (non-note-event) components - array position
sub CHANNEL()  { 0 }
sub PARAM()    { 4 } # Note: positions 1, 2, 3 are unused.
sub VALUE()    { 5 }

##  Event-filtering processing states
sub NORMAL()                { 0 } # Next event to be output as is
sub OVERRIDE()              { 1 } # Command override state
sub PROGRAM_CHANGE()        { 2 } # Program change to be sent
sub BANK_SELECT()           { 3 } # Bank select to be sent
sub EXTERNAL_CMD()          { 4 } # External command to be executed
sub REALTIME()              { 5 } # MIDI real-time message to be sent
sub PROGRAM_CHANGE_SAMPLE() { 6 } # Program change to be sent
sub MMC()                   { 7 } # MIDI machine control

##  Valid state transitions - hash reference
my $valid_state_transitions = {
    NORMAL()                => [OVERRIDE, NORMAL],
    OVERRIDE()              => [OVERRIDE, PROGRAM_CHANGE, NORMAL, BANK_SELECT,
                               EXTERNAL_CMD, REALTIME, PROGRAM_CHANGE_SAMPLE,
                               MMC],
    PROGRAM_CHANGE()        => [PROGRAM_CHANGE, NORMAL, OVERRIDE],
};

##  Event-filtering processing state-transition from/to components
##  The value of a state transition is an integer consisting of the sum of the
##  "from" state and the "to" state.  For example, the
##  PROGRAM_CHANGE_TO_OVERRIDE (PROGRAM_CHANGE -> OVERRIDE) transition is 5, the
##  sum of PROGRAM_CHANGE (2) and TO_OVERRIDE (3, defined below).
##  (Note: No FROM_... constants are defined because they are not needed - the
##  values of the three states that can function as "from" states in a state
##  transition (NORMAL, OVERRIDE, PROGRAM_CHANGE - See $valid_state_transitions
##  and "Event-filtering processing states", above) also function as the "from"
##  values.)
sub TO_NORMAL()                  { 0 } # Next event to be output as is
sub TO_OVERRIDE()                { 3 } # Command override state
sub TO_PROGRAM_CHANGE()          { 5 } # Program change to be sent
sub TO_BANK_SELECT()             { 7 } # Bank select to be sent
sub TO_EXTERNAL_CMD()            { 8 } # External command to be executed
sub TO_REALTIME()                { 9 } # MIDI real-time message to be sent
sub TO_PROGRAM_CHANGE_SAMPLE()   { 10 } # Program change to be sent
sub TO_MMC()                     { 11 } # MIDI machine control

# A map of state constant value (NORMAL, OVERRIDE, ...) to the corresponding
# TO_... value (e.g., $to_state_value->[REALTIME()] = TO_REALTIME() (9)):
state $to_state_value = [TO_NORMAL(), TO_OVERRIDE(), TO_PROGRAM_CHANGE(),
    TO_BANK_SELECT(), TO_EXTERNAL_CMD(), TO_REALTIME(),
    TO_PROGRAM_CHANGE_SAMPLE(), TO_MMC(),
];

##  Keys for "special" "external" commands
sub TERMINATE_CMD()  { '<terminate>' }      # Request for program termination
# Request for configured filter-specification report
sub REPORT_CFG_CMD() { '<filter-config-report>' }

## valid from->to values (sums)
sub NORMAL_TO_NORMAL                  { 0 }
sub OVERRIDE_TO_NORMAL                { 1 }
sub PROGRAM_CHANGE_TO_NORMAL          { 2 }
sub NORMAL_TO_OVERRIDE                { 3 }
sub OVERRIDE_TO_OVERRIDE              { 4 }
sub PROGRAM_CHANGE_TO_OVERRIDE        { 5 }
sub OVERRIDE_TO_PROGRAM_CHANGE        { 6 }
sub PROGRAM_CHANGE_TO_PROGRAM_CHANGE  { 7 }
sub OVERRIDE_TO_BANK_SELECT           { 8 }
sub OVERRIDE_TO_EXTERNAL_CMD          { 9 }
sub OVERRIDE_TO_REALTIME              { 10 }
sub OVERRIDE_TO_PROGRAM_CHANGE_SAMPLE { 11 }
sub OVERRIDE_TO_MMC                   { 12 }

## For convenience/debugging: state transition names
state $state_tr_name = {
	NORMAL_TO_NORMAL()                  => "NORMAL -> NORMAL",
	OVERRIDE_TO_NORMAL()                => "OVERRIDE -> NORMAL",
	PROGRAM_CHANGE_TO_NORMAL()          => "PROGRAM_CHANGE -> NORMAL",
	NORMAL_TO_OVERRIDE()                => "NORMAL -> OVERRIDE",
	OVERRIDE_TO_OVERRIDE()              => "OVERRIDE -> OVERRIDE",
	PROGRAM_CHANGE_TO_OVERRIDE()        => "PROGRAM_CHANGE -> OVERRIDE",
	OVERRIDE_TO_PROGRAM_CHANGE()        => "OVERRIDE -> PROGRAM_CHANGE",
	PROGRAM_CHANGE_TO_PROGRAM_CHANGE()  => "PROGRAM_CHANGE -> PROGRAM_CHANGE",
	OVERRIDE_TO_BANK_SELECT()           => "OVERRIDE -> BANK_SELECT",
	OVERRIDE_TO_EXTERNAL_CMD()          => "OVERRIDE -> EXTERNAL_CMD",
	OVERRIDE_TO_REALTIME()              => "OVERRIDE -> REALTIME",
	OVERRIDE_TO_PROGRAM_CHANGE_SAMPLE() => "OVERRIDE -> PROGRAM_CHANGE_SAMPLE",
	OVERRIDE_TO_MMC()                   => "OVERRIDE -> MMC",
};

# Formatted report of all valid explicit state transitions - for
# debugging/development
sub valid_state_transitions_report {
    my ($self) = @_;
    my $result = '';
    for my $from_state (sort keys %$valid_state_transitions) {
        for my $to_state (sort @{$valid_state_transitions->{$from_state}}) {
            $result .= $state_tr_name->{$from_state +
                $to_state_value->[$to_state]} . "\n";
        }
    }
    $result;
}

1;
