package MIDI_EventFilter;
# Copyright 2013  Jim Cochrane - GNU GPL, verson 2
# MIDI event filtering logic

use Mouse;
use Modern::Perl;
use constant::boolean;
use Data::Dumper;
use MIDI_Event;
use Regular_MIDI_Event;
use ProgramChange_MIDI_Event;
use BankSelect_MIDI_Event;
use ExternalCommand_MIDI_Event;
use RealTime_MIDI_Event;
use ProgramChangeSample_MIDI_Event;
use MMC_MIDI_Event;
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


###  Element change

# Subscribe the specified object to publishing of status-change notifications.
sub subscribe {
    my ($self, $o) = @_;
    push @{$self->_transposition_subscribers}, $o;
}


#####  Implementation

has _transposition_subscribers => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
);

# Convenience function: "$s1->$s2"
sub _state_tr {
    my ($s1, $s2) = @_;
    "$s1->$s2";
}

sub BUILD {
    my ($self) = @_;

    my $regular_event = Regular_MIDI_Event->new(config => $self->config,
        status_change_publisher => $self);
    my $bank_event = BankSelect_MIDI_Event->new(config => $self->config);
    my $program_change_sample = ProgramChangeSample_MIDI_Event->new(
        config => $self->config);
    my $program_change_event = ProgramChange_MIDI_Event->new(
        config => $self->config);
    my $external_cmd_event = ExternalCommand_MIDI_Event->new(
        config => $self->config);
    my $realtime_event = RealTime_MIDI_Event->new(config => $self->config);
    my $mmc_event = MMC_MIDI_Event->new(config => $self->config);
    if (not defined $self->config) { croak "code defect: config not set" }
    my $midimap = $self->_midi_event_map;
    # Initialize _midi_event_map -
    # key: state transition description [<state1>-><state2>]
    $midimap->{_state_tr(NORMAL(), NORMAL())} = $regular_event;
    $midimap->{_state_tr(NORMAL(), OVERRIDE())} = undef;            # (no-op)
# !!!!Note: this state transition may never be seen:
    $midimap->{_state_tr(BANK_SELECT(), NORMAL())} = $regular_event;
    $midimap->{_state_tr(OVERRIDE(), OVERRIDE())} = undef;          # (no-op)
    $midimap->{_state_tr(OVERRIDE(), PROGRAM_CHANGE())} = undef;    # (no-op)
    $midimap->{_state_tr(OVERRIDE(), NORMAL())} = undef;            # (no-op)
    $midimap->{_state_tr(OVERRIDE(), BANK_SELECT())} = $bank_event;
    $midimap->{_state_tr(OVERRIDE(), MMC())} = $mmc_event;
    $midimap->{_state_tr(OVERRIDE(), PROGRAM_CHANGE_SAMPLE())} =
        $program_change_sample;
    $midimap->{_state_tr(PROGRAM_CHANGE(), NORMAL())} = $program_change_event;
    $midimap->{_state_tr(PROGRAM_CHANGE, OVERRIDE())} = undef;      # (no-op)
    $midimap->{_state_tr(PROGRAM_CHANGE, PROGRAM_CHANGE())} = undef;# (no-op)
    $midimap->{_state_tr(OVERRIDE(), EXTERNAL_CMD())} = $external_cmd_event;
    $midimap->{_state_tr(OVERRIDE(), REALTIME())} = $realtime_event;
}


# map of MIDI_Event subtype instances: processing-state -> appropriate subtype
has _midi_event_map => (
    is      => 'ro',
    isa     => 'HashRef[MIDI_Event]',
    default => sub { {} },  # Initialized to empty hash reference.
);

1;

