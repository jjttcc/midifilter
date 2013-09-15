package MIDI_EventFilter;
# MIDI event filtering logic

use Mouse;
use Modern::Perl;
use constant::boolean;
use Data::Dumper;
use MIDI_Event;
use Static_MIDI_Event;
use Overriding_MIDI_Event;
use ProgramChange_MIDI_Event;
use BankSelect_MIDI_Event;
use ExternalCommand_MIDI_Event;

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
#say "event: ", Dumper($event);
    } else {
say "dispatch_next_event - no-op for $state_transition ",
Dumper(@alsa_event);
        # No event for this state transition (i.e., no-op)
    }
}


#####  Implementation

# Convenience function: "$s1->$s2"
sub _state_tr {
    my ($s1, $s2) = @_;
    "$s1->$s2";
}

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#   NORMAL()         => [OVERRIDE, NORMAL],
#   BANK_SELECT()    => [OVERRIDE, NORMAL],
#   OVERRIDE()       => [OVERRIDE, PROGRAM_CHANGE, NORMAL, BANK_SELECT],
#   PROGRAM_CHANGE() => [PROGRAM_CHANGE, NORMAL, OVERRIDE],
sub BUILD {
    my ($self) = @_;
    my $midimap = $self->_midi_event_map;
say "MEF BUILD - config: ", Dumper($self->config);
    # Initialize _midi_event_map -
    # key: state transition description [<state1>-><state2>]
    $midimap->{_state_tr(NORMAL(), NORMAL())} = Static_MIDI_Event->new(
            destinations => $self->config->destination_ports);
    $midimap->{_state_tr(NORMAL(), OVERRIDE())} = undef;            # (no-op)
    $midimap->{_state_tr(BANK_SELECT(), NORMAL())} = Static_MIDI_Event->new(
            destinations => $self->config->destination_ports);
    $midimap->{_state_tr(BANK_SELECT(), OVERRIDE())} = undef;       # (no-op)
    $midimap->{_state_tr(OVERRIDE(), OVERRIDE())} = undef;          # (no-op)
    $midimap->{_state_tr(OVERRIDE(), PROGRAM_CHANGE())} = undef;    # (no-op)
    $midimap->{_state_tr(OVERRIDE(), NORMAL())} = undef;            # (no-op)
    $midimap->{_state_tr(OVERRIDE(), BANK_SELECT())} =
        BankSelect_MIDI_Event->new(
            destinations => $self->config->destination_ports);
    $midimap->{_state_tr(PROGRAM_CHANGE(), NORMAL())} =
        ProgramChange_MIDI_Event->new(
            destinations => $self->config->destination_ports);
    $midimap->{_state_tr(PROGRAM_CHANGE, OVERRIDE())} = undef;      # (no-op)
    $midimap->{_state_tr(PROGRAM_CHANGE, PROGRAM_CHANGE())} = undef;# (no-op)
    $midimap->{_state_tr(OVERRIDE(), EXTERNAL_CMD())} =
        ExternalCommand_MIDI_Event->new(
            destinations => $self->config->destination_ports);
# !!!!bogus entry, for testing - remove when finished:
# !!!    $midimap->{_state_tr(NORMAL(), NORMAL())} = BankSelect_MIDI_Event->new(
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
if ($s) { say "HR - s: $s" } else { say "HR - dollar s is false" }
    my ($s1, $s2) = split(/->/, $s);
    my @parts = split(/->/, $s);
    _name_for_state($s1) . ' -> ' . _name_for_state($s2);
}

1;

