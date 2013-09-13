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

# !!!!These two modules use Filter::Macro so that their contents will be expanded
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
# !!!old:    my $state = $self->new_state($self->state, \@alsa_event);
    $self->execute_state_change(\@alsa_event);
# !!! my $event = $self->_midi_event_map->{$self->state};
say "$old_state->" . $self->state;
    my $event = $self->_midi_event_map->{"$old_state->" . $self->state};
    $event->event_data(\@alsa_event);
    $event->dispatch($self);
say "event: ", Dumper($event);
exit 102;
}

# Input the next, pending, event and according its type and the current state,
# dispatch (i.e., output, change state, or etc.) the event appropriately.
sub old____dispatch_next_event {
    my ($self) = @_;
# !!!!These may not be needed:
#   my $current_bank = [0, 0];
#   my $cmd_override = FALSE;
#   my $program_change = FALSE;
#   my $pc_top_range = FALSE;
#   my $myself;
# !!!!

    my @alsa_event = input();
    ++$event_count;
    my $type = $alsa_event[TYPE()];
    if ($type == NOTEON() or $type == NOTEOFF()) {
#  !!!!remove, no??:        my $data = $alsa_event[DATA()];
#  !!!!remove, no??: my ($channel, $pitch, $velocity, undef, undef) = @$data;
        my $event = $self->_midi_event_map->{$self->state()};
        $event->event_data(\@alsa_event);
        $event->dispatch($self);
    } elsif ($type == CONTROLLER()) {
    } else {
    }
}


#####  Implementation

sub BUILD {
    my ($self) = @_;
    my $midimap = $self->_midi_event_map;
say "MEF BUILD - config: ", Dumper($self->config);
# !!!!!_midi_event_map should perhaps map state transition to MIDI event -
# e.g.: PROGRAM_CHANGE-to-NORMAL => ProgramChange_MIDI_Event->new(...);
#    $midimap->{NORMAL()} = Normal_MIDI_Event->new(
#        destinations => $self->config->destination_ports);
#    $midimap->{OVERRIDE()} = Overriding_MIDI_Event->new(
#        destinations => $self->config->destination_ports);
#    $midimap->{PROGRAM_CHANGE()} = ProgramChange_MIDI_Event->new(
#        destinations => $self->config->destination_ports);
#    $midimap->{BANK_SELECT()} = BankSelect_MIDI_Event->new(
#        destinations => $self->config->destination_ports);

    # _midi_event_map key: state transition description
    $midimap->{PROGRAM_CHANGE() . '->' . NORMAL()} =
        ProgramChange_MIDI_Event->new(
            destinations => $self->config->destination_ports);
    $midimap->{NORMAL() . '->' . NORMAL()} = Normal_MIDI_Event->new(
            destinations => $self->config->destination_ports);
# etc....
}

# map of MIDI_Event subtype instances: processing-state -> appropriate subtype
has _midi_event_map => (
    is      => 'ro',
    isa     => 'HashRef[MIDI_Event]',
    default => sub { {} },  # Initialized to empty hash reference.
);


1;

