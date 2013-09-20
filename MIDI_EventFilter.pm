package MIDI_EventFilter;
# Copyright 2013  Jim Cochrane - GNU GPL, verson 2
# MIDI event filtering logic

use Mouse;
use Modern::Perl;
use constant::boolean;
use Data::Dumper;
use MIDI_Event;
use Static_MIDI_Event;
use ProgramChange_MIDI_Event;
use BankSelect_MIDI_Event;
use ExternalCommand_MIDI_Event;
use RealTime_MIDI_Event;
use ProgramChangeSample_MIDI_Event;
use Carp;

# This module uses Filter::Macro so that its contents will be expanded
# here (used for optimization) instead of the standard perl compile process.
use MIDI_StateMachine;

#####  Public interface

###  Access

# Configuration data
has config => (
    is      => 'ro',
    isa     => 'MIDI_Configuration',
);

my $event_count = 0;

# Input the next, pending, event and according its type and the current state,
# dispatch (i.e., output, change state, or etc.) the event appropriately.
sub dispatch_next_event {
    my ($self) = @_;

    my @alsa_event = input();
    ++$event_count;
    my $state_transition = $self->execute_state_change(\@alsa_event);
say STDERR "state_transition: ", human_readable_st($state_transition);
    my $event = $self->_midi_event_map->{$state_transition};
    if (defined $event) {
        $event->event_data(\@alsa_event);
        $event->dispatch($self);
    } else {
        # No event for this state transition (i.e., no-op)
    }
}


#####  Implementation

# Convenience function: "$s1->$s2"
sub _state_tr {
    my ($s1, $s2) = @_;
    "$s1->$s2";
}

sub BUILD {
    my ($self) = @_;

    if (not defined $self->config) { croak "code defect: config not set" }
    my $midimap = $self->_midi_event_map;
    # Initialize _midi_event_map -
    # key: state transition description [<state1>-><state2>]
    $midimap->{_state_tr(NORMAL(), NORMAL())} = Static_MIDI_Event->new(
        config => $self->config);
    $midimap->{_state_tr(NORMAL(), OVERRIDE())} = undef;            # (no-op)
# !!!!Note: this state transition may never be seen:
    $midimap->{_state_tr(BANK_SELECT(), NORMAL())} = Static_MIDI_Event->new(
#        config => undef);   #!!!temporary test to cause core dump if it's used!!
        config => $self->config);
    $midimap->{_state_tr(BANK_SELECT(), OVERRIDE())} = undef;       # (no-op)
    $midimap->{_state_tr(OVERRIDE(), OVERRIDE())} = undef;          # (no-op)
    $midimap->{_state_tr(OVERRIDE(), PROGRAM_CHANGE())} = undef;    # (no-op)
    $midimap->{_state_tr(OVERRIDE(), NORMAL())} = undef;            # (no-op)
    $midimap->{_state_tr(OVERRIDE(), BANK_SELECT())} =
        BankSelect_MIDI_Event->new(config => $self->config);
    $midimap->{_state_tr(OVERRIDE(), PROGRAM_CHANGE_SAMPLE())} =
        ProgramChangeSample_MIDI_Event->new(config => $self->config);
    $midimap->{_state_tr(PROGRAM_CHANGE(), NORMAL())} =
        ProgramChange_MIDI_Event->new(config => $self->config);
    $midimap->{_state_tr(PROGRAM_CHANGE, OVERRIDE())} = undef;      # (no-op)
    $midimap->{_state_tr(PROGRAM_CHANGE, PROGRAM_CHANGE())} = undef;# (no-op)
    $midimap->{_state_tr(OVERRIDE(), EXTERNAL_CMD())} =
        ExternalCommand_MIDI_Event->new(config => $self->config);
    $midimap->{_state_tr(OVERRIDE(), REALTIME())} =
        RealTime_MIDI_Event->new(config => $self->config);
}


# map of MIDI_Event subtype instances: processing-state -> appropriate subtype
has _midi_event_map => (
    is      => 'ro',
    isa     => 'HashRef[MIDI_Event]',
    default => sub { {} },  # Initialized to empty hash reference.
);

# Human-readable state transition - for debugging
sub human_readable_st {
    my ($s) = @_;
    my ($s1, $s2) = split(/->/, $s);
    my @parts = split(/->/, $s);
    _name_for_state($s1) . ' -> ' . _name_for_state($s2);
}

1;

