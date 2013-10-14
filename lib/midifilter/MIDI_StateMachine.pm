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


#####  Public interface

###  Access

# Current MIDI-event processing state
has state => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { NORMAL(); },
    writer   => 'set_state',
    init_arg => undef,   # Not allowed in 'new' method.
);

# Configuration settings - virtual feature
sub config {
}

###  Basic operations

my $event_count = 0;

# Input the next, pending, event and according its type and the current state,
# dispatch (i.e., output, change state, or etc.) the event appropriately.
sub dispatch_next_event {
    my ($self) = @_;

    my @alsa_event = input();
    ++$event_count;
my $event = $self->next_event(\@alsa_event);
=cut=
    my $state_transition = $self->execute_state_change(\@alsa_event);
    if ($DEBUG) {
        say STDERR "state_transition: ", human_readable_st($state_transition);
    }
    my $event = $self->_midi_event_table->[$state_transition];
=cut=
    if (defined $event) {
        $event->event_data(\@alsa_event);
        $event->dispatch($self);
    } else {
        # No event for this state transition (i.e., no-op)
    }
}

sub next_event {
    my ($self, $alsa_event) = @_;
    my $state_transition = $self->execute_state_change($alsa_event);
    if ($DEBUG) {
        say STDERR "state_transition: ", human_readable_st($state_transition);
    }
    $self->_midi_event_table->[$state_transition];
}

#####  Implementation (non-public)

# Subscribers to transposition-related state changes (virtual feature that
# must be implemented by descendant class)
sub _transposition_subscribers {
}

# map of MIDI_Event subtype instances: processing-state -> appropriate subtype
# (virtual feature)
sub _midi_event_table {
}

# Based on the current state and $alsa_event (the last ALSA-MIDI event
# received), change the state and take any other appropriate actions.
# Return the resulting state transition (integer).
sub execute_state_change {
    my ($self, $alsa_event) = @_;

    state $add_to_progch;
    my $old_state = $self->state;
    my $new_state = $old_state;
    my $type = $alsa_event->[TYPE()];
    if ($old_state == OVERRIDE()) {
        $new_state = $self->override_state_transition($alsa_event, $old_state,
            \$add_to_progch);
    } elsif ($old_state == NORMAL()) {
        my ($param);
        (undef, undef, undef, undef, $param) = @{$alsa_event->[DATA()]};
        if ($type == CONTROLLER() and $param ==
                $self->config->filter_spec->override_cc_control_number) {
            $new_state = OVERRIDE();
        }   # (else no state change, let event be sent on as is.)
    } else {
        $new_state = $self->progchange_state_transition($alsa_event,
            $old_state, \$add_to_progch);
    }
    if ($DEBUG) {
        _check_state_change($old_state, $self->state);
    }
    if ($new_state != $old_state) {
        $self->set_state($new_state);
    }
    $old_state + $to_state_value->[$new_state];
}

# The new state, transitioned from an original state of OVERRIDE, according
# to the contents of $alsa_event and $old_state.
# Note: $add_to_progch is expected to be a scalar reference and the
# referenced value might be modified.
sub override_state_transition {
    my ($self, $alsa_event, $old_state, $add_to_progch) = @_;

    state $prog_ch_high_pitch = $self->config->filter_spec->program_change_high;
    state $prog_ch_low_pitch = $self->config->filter_spec->program_change_low;
    state $prog_ch_pitches = {$prog_ch_high_pitch => TRUE,
        $prog_ch_low_pitch => TRUE};
    state $bank_sel_up_pitch = $self->config->filter_spec->bank_select_up;
    state $bank_sel_down_pitch = $self->config->filter_spec->bank_select_down;
    state $bank_sel_pitches = {$bank_sel_down_pitch => TRUE,
        $bank_sel_up_pitch => TRUE};
    state $external_commands = $self->config->filter_spec->external_commands;
    state $is_extcmd;
    for my $value (keys %$external_commands) {
        $is_extcmd->{$value} = TRUE;
    }
    state $is_rt = {};
    $is_rt->{$self->config->filter_spec->realtime_start} = TRUE;
    $is_rt->{$self->config->filter_spec->realtime_stop} = TRUE;
    $is_rt->{$self->config->filter_spec->realtime_continue} = TRUE;
    my $result = $old_state;
    my ($pitch, $velocity);
    my ($param);
    my $type = $alsa_event->[TYPE()];
    if ($type == NOTEON() or $type == NOTEOFF()) {
        (undef, $pitch, $velocity, undef, undef) = @{$alsa_event->[DATA()]};
        if ($type == NOTEOFF() or $velocity == 0) {   # NOTE-OFF
            if ($prog_ch_pitches->{$pitch}) {
                $result = PROGRAM_CHANGE();
                $$add_to_progch = $pitch == $prog_ch_high_pitch;
            } elsif ($bank_sel_pitches->{$pitch}) {
                $result = BANK_SELECT();
            } elsif ($is_extcmd->{$pitch}) {
                $result = EXTERNAL_CMD();
            } elsif ($is_rt->{$pitch}) {
                $result = REALTIME();
            } else {
                # Remaining override -> ... transitions
                $result = $self->override_state_transition2($pitch);
            }
        }
    }
    $result;
}

# Helper to override_state_transition - i.e., does the remaining work.
# Returns the new state.
sub override_state_transition2 {
    my ($self, $pitch) = @_;
    my $result;

    state $is_pc_sample->{
        $self->config->filter_spec->program_change_sample} = TRUE;
    state $is_cancel_pc_sample->{
        $self->config->filter_spec->cancel_program_change_sample} = TRUE;
    state $is_stopped_pc_sample->{
        $self->config->filter_spec->stop_program_change_sample} = TRUE;
    state $is_continued_pc_sample->{
        $self->config->filter_spec->continue_program_change_sample} = TRUE;
    # reset - not canceled, not stopped:
    $self->config->program_change_sample_canceled(FALSE);
    $self->config->program_change_sample_stopped(FALSE);
    if ($is_pc_sample->{$pitch}) {
        $result = PROGRAM_CHANGE_SAMPLE();
    } elsif ($is_cancel_pc_sample->{$pitch}) {
        $result = PROGRAM_CHANGE_SAMPLE();
        $self->config->program_change_sample_canceled(TRUE);
    } elsif ($is_stopped_pc_sample->{$pitch}) {
        $result = PROGRAM_CHANGE_SAMPLE();
        $self->config->program_change_sample_stopped(TRUE);
    } elsif ($is_continued_pc_sample->{$pitch}) {
        $result = PROGRAM_CHANGE_SAMPLE();
        $self->config->program_change_sample_stopped(FALSE);
    } else {
        $result = $self->override_state_transition3($pitch);
    }
    $result;
}

sub override_state_transition3 {
    my ($self, $pitch) = @_;
    my $result;

    state $fspec = $self->config->filter_spec;
    if ($fspec->transpositions_configured and
            $fspec->transposition_specs->{$pitch}) {
        # A transposition toggle has been invoked - notify subscribers:
        for my $sub (@{$self->_transposition_subscribers}) {
            $sub->toggle_transposition($pitch);
        }
        $result = NORMAL();
    } elsif (%{$fspec->mmc_command} and $fspec->mmc_command->{$pitch}) {
        $result = MMC();
    } else {
        $result = NORMAL();     # default
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
    state $override_cc_number =
        $self->config->filter_spec->override_cc_control_number;
    state $lowest_pitch = $self->config->filter_spec->bottom_note_value;
    state $highest_pitch = $self->config->filter_spec->top_note_value;
    if ($type == NOTEON() or $type == NOTEOFF()) {
        (undef, $pitch, $velocity, undef, undef) = @{$alsa_event->[DATA()]};
        if ($type == NOTEOFF() or $velocity == 0) {   # i.e., NOTE-OFF
            $result = NORMAL();
            if ($$add_to_progch) {   # Note: pitch becomes program #.
                $pitch += (127 - $highest_pitch);   # e.g.: 108 => 127 [88key]
            } else {
                $pitch -= $lowest_pitch;    # e.g.: 21 => 0 [88 keys]
            }
            $alsa_event->[DATA()]->[PITCH()] = $pitch;
        }   # (else discard the note-on event.)
    } elsif ($type == CONTROLLER()) {
        my ($param) = $alsa_event->[PARAM()];
        if ($param == $override_cc_number) {
            $result = OVERRIDE();
        }
    }
    $result;
}

### Utility routines

sub _name_for_state {
    my ($s) = @_;
    state $name_for = {
        NORMAL()                => 'NORMAL',
        OVERRIDE()              => 'OVERRIDE',
        PROGRAM_CHANGE()        => 'PROGRAM_CHANGE',
        BANK_SELECT()           => 'BANK_SELECT',
        EXTERNAL_CMD()          => 'EXTERNAL_CMD',
        REALTIME()              => 'REALTIME',
        PROGRAM_CHANGE_SAMPLE() => 'PROGRAM_CHANGE_SAMPLE',
        MMC()                   => 'MMC',
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

# Human-readable state transition - for debugging
sub human_readable_st {
    my ($state_tr) = @_;
    $state_tr_name->{$state_tr};
}

sub _code_defect {
    my ($line) = @_;
    croak "[MSM] Fatal error: code defect [line " . $line . ']';
}

1;
