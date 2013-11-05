package BankSelect_MIDI_Event;
# MIDI (note) events to be output as two bank-select (MSB and LSB) events
# and a program-change (patch 0) event

use Mouse;
use Modern::Perl;
use constant::boolean;
use feature qw(state);
use Carp;
use Data::Dumper;
use MIDI_Facilities;
use Announcer;


extends 'MIDI_Event';

#####  Public interface

has bank_select_matrix => (
    is => 'ro',
    isa => 'ArrayRef[ArrayRef]',
    required => 1,
);

#####  Interface implementation (public)

has _current_bank => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    writer  => '_set_current_bank',
);

sub dispatch {
    my ($self, $client) = @_;

    state $program1 = 0;
    state $matrix = $self->bank_select_matrix;
    # (Optimization: set @destinations only once:)
    state $destinations = $self->config->destination_ports;
    # myself -> source for output calls - not expected to change:
    state $myself = $self->destination();
    state $queue = undef;
    state $time = 0;
    state $bank_select_down = $self->config->filter_spec->bank_select_down;
    state $announcer = $self->config->filter_spec->announcer;
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my (undef, $flags, $tag,  undef, undef, undef, undef, $data) =
        @{$self->event_data};
    my ($channel, $pitch) = @$data;
    if ($pitch == $bank_select_down) {
        $self->previous_bank();
    } else {
        $self->next_bank();
    }
    my $bank_idx = $self->_current_bank;
    my $bank_column = $matrix->[$self->_current_bank];
    my ($msb, $lsb) = @{$bank_column}[BANK_MSB(), BANK_LSB()];
    $self->_current_bank;
    $announcer->announce("Bank $msb, $lsb");
    for my $dest (@$destinations) {
        # Construct and send the MSB message.
        my @bankch_msb = (CONTROLLER(), $flags, $tag,
            $queue, $time, $myself, $dest,
            [$channel, 0, 0, 0, BANKMSB_SELECT(), $msb]);
        output(@bankch_msb);
        my @bankch_lsb = (CONTROLLER(), $flags, $tag,
            $queue, $time, $myself, $dest,
            [$channel, 0, 0, 0, BANKLSB_SELECT(), $lsb]);
        output(@bankch_lsb);
# !!!Possible improvement: keep track of the current program (may require a
# program query in $client) and send that here instead of prog 0.
# (!!!Also, perhaps, keep track of the current bank - in $client.)
        my @pgmch = (PGMCHANGE(), $flags, $tag, $queue,
            $time, $myself, $dest, [$channel, 0, 0, 0, 0, $program1]);
        # Start the new bank at program 0 (first program):
        output(@pgmch);
    }
    $client->set_state(NORMAL());
}


#####  Implementation (non-public)

# Bank-select indexes
sub BANK_NAME() { 0 }
sub BANK_MSB()  { 1 }
sub BANK_LSB()  { 2 }

# Increment the current-bank index ($self->_current_bank).
sub next_bank {
    my ($self) = @_;
    if ($self->_current_bank + 1 >= @{$self->bank_select_matrix}) {
        $self->_set_current_bank(0);
    } else {
        $self->_set_current_bank($self->_current_bank + 1);
    }
}

# Decrement the current-bank index ($self->_current_bank).
sub previous_bank {
    my ($self) = @_;
    if ($self->_current_bank == 0) {
        $self->_set_current_bank(@{$self->bank_select_matrix} - 1);
    } else {
        $self->_set_current_bank($self->_current_bank - 1);
    }
}


1;
