package MIDI_StateMachine;
# State-transition logic for ALSA-MIDI filtering

use Mouse;
use Filter::Macro;  # 'use MIDI_StateMachine' provides inline expansion.
use Modern::Perl;
use constant::boolean;
use List::Util qw(first);
use Carp;
use Data::Dumper;
use feature qw(state);

use MIDI_Facilities;


###  Constants

sub DEBUG() { 1 }

# valid state transitions - hash reference
my $valid_state_transitions = {
    NORMAL()         => [OVERRIDE, NORMAL],
    BANK_SELECT()    => [OVERRIDE, NORMAL],
    REALTIME()       => [OVERRIDE, NORMAL],
    OVERRIDE()       => [OVERRIDE, PROGRAM_CHANGE, NORMAL, BANK_SELECT,
                        EXTERNAL_CMD],
    PROGRAM_CHANGE() => [PROGRAM_CHANGE, NORMAL, OVERRIDE],
    EXTERNAL_CMD()   => [OVERRIDE, NORMAL],
};


# (!!These might want to become configurable.)
my $PC_pitch     =  {B7() => TRUE, C8() => TRUE};   # program-change pitch
my $BNKSL_pitch  =  {Bb7() => TRUE, A7() => TRUE};  # bank-select pitch
my $PC_add       =  {B7() => TRUE};                 # add to PC value
my $EXTC_pitch   =  {A0() => TRUE};                 # external command
my $RT_pitch     =  {A1() => TRUE, Bb1() => TRUE,   # real-time message
                     B1() => TRUE};                 # (start, stop, cont)
###  Access

# Current MIDI-event processing state
has state => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { NORMAL(); },
    writer   => '_set_state',
    init_arg => undef,   # Not allowed in 'new' method.
);


#####  Implementation (non-public)

##[Notes: For now, if override, don't bother to check: $pitch >= CTL_START.
# Lower pitches will be discarded.  (It might make sense to always do this.)]

# Based on the current state and $alsa_event (the last ALSA-MIDI event
# received), change the state and take any other appropriate actions.
# Return the resulting state transition, as a string.
sub execute_state_change {
    my ($self, $alsa_event) = @_;

    state $add_to_progch;
    my $old_state = $self->state;
    my $new_state = $old_state;
    my $type = $alsa_event->[TYPE()];
    if ($old_state == OVERRIDE()) {
        $new_state = $self->override_state_transition($alsa_event, $old_state,
            \$add_to_progch);
    } elsif ($old_state == NORMAL() or $old_state == BANK_SELECT()) {
        my ($param); #!!!Check: will $old_state == BANK_SELECT ever occur here?
if ($old_state == BANK_SELECT()) {say "old_state == BANK_SELECT detected!!!"}
        (undef, undef, undef, undef, $param) = @{$alsa_event->[DATA()]};
        if ($type == CONTROLLER() and $param == CHANNEL_VOLUME()) {
            $new_state = OVERRIDE();
        }   # (else no state change, let event be sent on as is.)
    } else {    # PROGRAM_CHANGE(???!!!)
        $new_state = $self->progchange_state_transition($alsa_event,
            $old_state, \$add_to_progch);
    }
    if (DEBUG()) { _check_state_change($old_state, $self->state); }
    if ($new_state != $old_state) {
        $self->_set_state($new_state);
    }
    "$old_state->$new_state";
}

# The new state (transitioned from an original state of OVERRIDE), according
# to the contents of $alsa_event and $old_state.
# Note: $add_to_progch is expected to be a scalar reference and the
# referenced value might be modified.
sub override_state_transition {
    my ($self, $alsa_event, $old_state, $add_to_progch) = @_;

    my $result = $old_state;
    my ($pitch, $velocity);
    my ($param);
    my $type = $alsa_event->[TYPE()];
    if ($type == NOTEON() or $type == NOTEOFF()) {
        (undef, $pitch, $velocity, undef, undef) = @{$alsa_event->[DATA()]};
        if ($type == NOTEOFF() or $velocity == 0) {   # NOTE-OFF
            if ($PC_pitch->{$pitch}) {
                $result = PROGRAM_CHANGE();
                $$add_to_progch = $PC_add->{$pitch};
            } elsif ($BNKSL_pitch->{$pitch}) {
                $result = BANK_SELECT();
            } elsif ($EXTC_pitch->{$pitch}) {
                $result = EXTERNAL_CMD();
            } elsif ($RT_pitch->{$pitch}) {
                $result = REALTIME();
            } else {
                $result = NORMAL();  # override mode canceled
            }
        } else {
            # no-op: Discard NOTE-ON event.
        }
    } else {
        # not a note event - discard
    }
    $result;
}

# The new state (transitioned from an original state of PROGRAM_CHANGE),
# according to the contents of $alsa_event and $old_state.
# Note: $add_to_progch is expected to be a scalar reference.
sub progchange_state_transition {
    my ($self, $alsa_event, $old_state, $add_to_progch) = @_;

    my $result = $old_state;
    my ($pitch, $velocity);
    my $type = $alsa_event->[TYPE()];
    if ($old_state != PROGRAM_CHANGE()) { _code_defect(__LINE__) }  #????
    if ($type == NOTEON() or $type == NOTEOFF()) {
        (undef, $pitch, $velocity, undef, undef) = @{$alsa_event->[DATA()]};
        if ($type == NOTEOFF() or $velocity == 0) {   # i.e., NOTE-OFF
            $result = NORMAL();
            if ($$add_to_progch) {   # Note: pitch becomes program #.
                $pitch += (127 - HIGHEST_88KEY_PITCH());    # i.e.: 108 => 127
            } else {
                $pitch -= LOWEST_88KEY_PITCH();             # i.e.: 21 => 0
            }
            $alsa_event->[DATA()]->[PITCH()] = $pitch;
        }   # (else discard the note-on event.)
    } elsif ($type == CONTROLLER()) {
        my ($param) = $alsa_event->[PARAM()];
        if ($param == CHANNEL_VOLUME()) {
            $result = OVERRIDE();
        }
    }
    $result;
}

### Utility routines

sub _name_for_state {
    my ($s) = @_;
    state $name_for = {
        NORMAL()         => 'NORMAL',
        OVERRIDE()       => 'OVERRIDE',
        PROGRAM_CHANGE() => 'PROGRAM_CHANGE',
        BANK_SELECT()    => 'BANK_SELECT',
        EXTERNAL_CMD()   => 'EXTERNAL_CMD',
        REALTIME()       => 'REALTIME',
    };
    $name_for->{$s};
}

# Check transition from $state1 to $state2.  If it's invalid, die with an
# error message.  If it's valid, return TRUE.
sub _check_state_change {
    my ($state1, $state2) = @_;
    if (not defined $state1 or not defined $state2) {
        croak "_check_state_change: one or both states not defined: ",
            Dumper($state1, $state2);
    }
    my $valid = FALSE;
    my $states = $valid_state_transitions->{$state1};
    if (defined $states) {
        $valid = defined first { $_ == $state2 } @$states;
    }
    if (not $valid) {
        say "state1: ", _name_for_state($state1), ", state2: ",
        _name_for_state($state2);
        croak "_check_state_change: invalid state transition: ",
            _name_for_state($state1), ' -> ', _name_for_state($state2);
    }
    $valid;
}

sub _code_defect {
    my ($line) = @_;
    croak "Fatal error: code defect [line " . $line . ']';
}

1;
