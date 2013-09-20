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


#####  Interface implementation (public)

sub dispatch {
    my ($self, $client) = @_;

    state $current_bank = [0, 0];
    state $program1 = 0;
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
        $current_bank = previous_bank($current_bank);
    } else {
        $current_bank = next_bank($current_bank);
    }
    my ($msb, $lsb) = @$current_bank;
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
    $client->_set_state(NORMAL());
}


#####  Implementation (non-public)

# Next valid bank-select [MSB, LSB] value based on $currbank
# [Specific to Motif/XS]
sub next_bank {
    my ($currbank) = @_;
    my $result = [];
    my ($msb, $lsb) = @$currbank;
    # For Motif/XS - only used bank-select MSB of 0, 63, or 127.
    if ($msb == 0) {
            $result = [63, 0]; # Pre1
    } elsif ($msb == 63) {
        if ($lsb >= 0 and $lsb <= 9) {
            $result = [$msb, $lsb + 1];
        } elsif ($lsb == 10) {
            $result = [$msb, 32];
        } elsif ($lsb == 32) {
            $result = [$msb, 40];
        } elsif ($lsb == 40) {
            $result = [$msb, 50];
        } elsif ($lsb == 50) {
            $result = [$msb, 60];
        } elsif ($lsb == 60) {
            $result = [127, 0]; # GM drum
        }
    } elsif ($msb == 127) {
            $result = [0, 0]; # GM
    } else {
        croak "Fatal error: code defect [line " . __LINE__ . ']';
    }
    $result;
}

# Previous valid bank-select [MSB, LSB] value based on $currbank
# [Specific to Motif/XS]
sub previous_bank {
    my ($currbank) = @_;
    my $result = [];
    my ($msb, $lsb) = @$currbank;
    # For Motif/XS - only used bank-select MSB of 0, 63, or 127.
    if ($msb == 0) {
        $result = [127, 0];     # GM drum
    } elsif ($msb == 63) {
        if ($lsb == 0) {
            $result = [0, 0];   # GM
        } elsif ($lsb >= 1 and $lsb <= 10) {
            $result = [$msb, $lsb - 1];
        } elsif ($lsb == 32) {
            $result = [$msb, 10];
        } elsif ($lsb == 40) {
            $result = [$msb, 32];
        } elsif ($lsb == 50) {
            $result = [$msb, 40];
        } elsif ($lsb == 60) {
            $result = [$msb, 50];
        }
    } elsif ($msb == 127) {
        $result = [63, 60]; # Mix voice
    } else {
        croak "Fatal error: code defect [line " . __LINE__ . ']';
    }
    $result;
}

1;
