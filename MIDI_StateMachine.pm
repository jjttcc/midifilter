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
# Event-filtering processing states
sub NORMAL()         { 0 } # Next event to be output as is
sub OVERRIDE()       { 1 } # Command override state
sub PROGRAM_CHANGE() { 2 } # Program change to be sent
sub BANK_SELECT()    { 3 } # Bank select to be sent

# valid state transitions - hash reference
my $valid_state_transitions = {
    NORMAL()         => [OVERRIDE, NORMAL],
    OVERRIDE()       => [OVERRIDE, PROGRAM_CHANGE, NORMAL],
    PROGRAM_CHANGE() => [PROGRAM_CHANGE, NORMAL]
};

# !!!!!!!!!!!Do we need? (possibly not):
# sub NORMAL_TO_OVERRIDE() { 0 }, etc.
# !!!!to be used as key to obtain the appropriate MIDI_Event descendant.

# (!!These might want to become configurable.)
my $PC_pitch = {B7() => TRUE, C8() => TRUE};    # program-change pitch
my $BNKSL_pitch = {B7() => TRUE, C8() => TRUE}; # bank-select pitch

###  Access

# Current MIDI-event processing state
has state => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { NORMAL(); },
    writer   => '_set_state',
    init_arg => undef,   # Not allowed in 'new' method.
);


### Utility routines

##[Notes: For now, if override, don't bother to check: $pitch >= CTL_START.
# Lower pitches will be discarded.  (It might make sense to always do this.)
# Based on the current state and $alsa_event (the last ALSA-MIDI event
# received), change the state and take any other appropriate actions.
sub execute_state_change {
    my ($self, $alsa_event) = @_;

    my $old_state = $self->state;
    my $type = $alsa_event->[TYPE()];
    if ($old_state == OVERRIDE()) {
        if ($type == NOTEON() or $type == NOTEOFF()) {
            my $data = $alsa_event->[DATA()];
            my (undef, $pitch, $velocity, undef, undef) = @$data;
            if ($velocity == 0) {   # NOTE-OFF
                if ($PC_pitch->{$pitch}) {
                    $self->_set_state(PROGRAM_CHANGE());
                } elsif ($BNKSL_pitch->{$pitch}) {
                    $self->_set_state(BANK_SELECT());
                }
            } else {
                # no-op: Discard NOTE-ON event.
            }
        }
    }
    if (DEBUG()) { check_state_change($old_state, $self->state); }
}

##[Notes: For now, if override, don't bother to check: $pitch >= CTL_START.
# Lower pitches will be discarded.  (It might make sense to always do this.)
# The new state, based on the status of $state and $alsa_event (the last
# ALSA-MIDI event received).
# !!!!Possible side effects: $alsa_event components may be modified.???
sub new_state___old {
    my ($self, $state, $alsa_event) = @_;

    my $old_state = $state;
    my $result = $state;
    my $type = $alsa_event->[TYPE()];
    if ($state == OVERRIDE()) {
        if ($type == NOTEON() or $type == NOTEOFF()) {
            my $data = $alsa_event->[DATA()];
            my (undef, $pitch, $velocity, undef, undef) = @$data;
            if ($velocity == 0) {   # NOTE-OFF
                if ($PC_pitch->{$pitch}) {
                    $result = PROGRAM_CHANGE();
                } elsif ($BNKSL_pitch->{$pitch}) {
                    $result = BANK_SELECT();
                }
            } else {
                # no-op: Discard NOTE-ON event.
            }
        }
    }
    if (DEBUG()) { check_state_change($old_state, $result); }
    $result;
}



sub name_for_state {
    my ($s) = @_;
    state $name_for = {
        NORMAL()         => 'NORMAL',
        OVERRIDE()       => 'OVERRIDE',
        PROGRAM_CHANGE() => 'PROGRAM_CHANGE'
    };
    $name_for->{$s};
}

# Check transition from $state1 to $state2.  If it's invalid, die with an
# error message.  If it's valid, return TRUE.
sub check_state_change {
use IO::File;
    my ($state1, $state2) = @_;
    if (not defined $state1 or not defined $state2) {
        croak "check_state_change: one or both states not defined: ",
            Dumper($state1, $state2);
    }
    my $valid = FALSE;
    my $states = $valid_state_transitions->{$state1};
    if (defined $states) {
        $valid = defined first { $_ == $state2 } @$states;
    }
    if (not $valid) {
        croak "check_state_change: invalid state transition: ",
            name_for_state($state1), ' -> ', name_for_state($state2);
    }
    $valid;
}

1;
