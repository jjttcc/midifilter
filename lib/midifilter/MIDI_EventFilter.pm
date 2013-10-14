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
    my $miditable = $self->_midi_event_table;

    # Initialize _midi_event_table -
    # key: state transition (from-state + to-state)
    $miditable->[NORMAL_TO_NORMAL()] = $regular_event;
    $miditable->[NORMAL_TO_OVERRIDE()] = undef;            # (no-op)
    $miditable->[OVERRIDE_TO_OVERRIDE()] = undef;          # (no-op)
    $miditable->[OVERRIDE_TO_PROGRAM_CHANGE()] = undef;    # (no-op)
    $miditable->[OVERRIDE_TO_NORMAL()] = undef;            # (no-op)
    $miditable->[OVERRIDE_TO_BANK_SELECT()] = $bank_event;
    $miditable->[PROGRAM_CHANGE_TO_NORMAL()] = $program_change_event;
    $miditable->[PROGRAM_CHANGE_TO_OVERRIDE()] = undef;      # (no-op)
    $miditable->[PROGRAM_CHANGE_TO_PROGRAM_CHANGE()] = undef;# (no-op)
    $miditable->[OVERRIDE_TO_EXTERNAL_CMD()] = $external_cmd_event;
    $miditable->[OVERRIDE_TO_REALTIME()] = $realtime_event;
    $miditable->[OVERRIDE_TO_PROGRAM_CHANGE_SAMPLE()] = $program_change_sample;
    $miditable->[OVERRIDE_TO_MMC()] = $mmc_event;
}


# map of MIDI_Event subtype instances: processing-state -> appropriate subtype
has _midi_event_table => (
    is      => 'ro',
    isa     => 'ArrayRef[MIDI_Event]',
    default => sub { [] },  # Initialized to empty hash reference.
);

1;

