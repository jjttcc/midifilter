package MIDI_EventFilter;
# MIDI event filtering logic

use Mouse;
use Modern::Perl;
use constant::boolean;
use Data::Dumper;
use MIDI_Event;
use Normal_MIDI_Event;
use Overriding_MIDI_Event;
use ProgramChange_MIDI_Event;
use BankSelect_MIDI_Event;

# This module uses Filter::Macro so that its contents will be expanded
# here (used for optimization) instead of the standard perl compile process.
use MIDI_StateMachine;

#####  Public interface

###  Access

=cut=
# Current MIDI-event processing state
has state => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { NORMAL(); },
    writer   => '_set_state',
    init_arg => undef,   # Not allowed in 'new' method.
);
=cut=

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
    my $old_state = $self->state;
    my $state_transition = $self->execute_state_change(\@alsa_event);
say "state_transition: ", $state_transition;
    my $event = $self->_midi_event_map->{$state_transition};
    if (defined $event) {
        $event->event_data(\@alsa_event);
        $event->dispatch($self);
say "event: ", Dumper($event);
    } else {
        # No event for this state transition (i.e., no-op)
    }
}


#####  Implementation

sub BUILD {
    my ($self) = @_;
    my $midimap = $self->_midi_event_map;
say "MEF BUILD - config: ", Dumper($self->config);
    # _midi_event_map key: state transition description [<state1>-><state2>]
    $midimap->{PROGRAM_CHANGE() . '->' . NORMAL()} =
        ProgramChange_MIDI_Event->new(
            destinations => $self->config->destination_ports);
    $midimap->{NORMAL() . '->' . NORMAL()} = Normal_MIDI_Event->new(
            destinations => $self->config->destination_ports);
# !!!!bogus entry, for testing - remove when finished:
# !!!    $midimap->{NORMAL() . '->' . NORMAL()} = BankSelect_MIDI_Event->new(
    $midimap->{OVERRIDE() . '->' . BANK_SELECT()} = BankSelect_MIDI_Event->new(
            destinations => $self->config->destination_ports);
    $midimap->{OVERRIDE() . '->' . PROGRAM_CHANGE()} = undef;   # (no-op)
# etc....
}

# map of MIDI_Event subtype instances: processing-state -> appropriate subtype
has _midi_event_map => (
    is      => 'ro',
    isa     => 'HashRef[MIDI_Event]',
    default => sub { {} },  # Initialized to empty hash reference.
);


1;

