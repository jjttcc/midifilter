package BankSelect_MIDI_Event;
# MIDI events to be output as two bank-select (MSB and LSB) events and a
# program-change (patch 0) event

use Mouse;
use Modern::Perl;
use constant::boolean;
use feature qw(state);
use Carp;
use Data::Dumper;
use MIDI_Facilities;


extends 'MIDI_Event';


#####  Interface implementation (public)

sub dispatch {
    my ($self, $client) = @_;

    state $current_bank = [0, 0];
    state $program1 = 0;
say "dispatch [for ", ref $self, "]: self: ", Dumper($self);
    # (Optimization: set @destinations only once:)
    state $destinations = $self->destinations;
    # myself -> source for output calls - not expected to change:
    state $myself = $self->destination();
    state $queue = undef;
    state $time = 0;
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my (undef, $flags, $tag,  undef, undef, undef, undef, $data) =
        @{$self->event_data};
say "data: ", Dumper($data);
    my ($channel, $pitch) = @$data;
    if ($pitch == DOWN_PITCH()) {
        $current_bank = previous_bank($current_bank);
    } else {
        $current_bank = next_bank($current_bank);
    }
    for my $dest (@$destinations) {
        my ($msb, $lsb) = @$current_bank;
        # Construct and send the MSB message.
        my @bankch_msb = (CONTROLLER(), $flags, $tag,
            $queue, $time, $myself, $dest,
            [$channel, 0, 0, 0, BANKMSB_SELECT(), $msb]);
say "sending bank/MSB [$msb] (\n" . Dumper(@bankch_msb) . ')' if FALSE;
        output(@bankch_msb);
say("sending bank/MSB [$msb]", @bankch_msb);
        my @bankch_lsb = (CONTROLLER(), $flags, $tag,
            $queue, $time, $myself, $dest,
            [$channel, 0, 0, 0, BANKLSB_SELECT(), $lsb]);
say "sending bank/LSB [$lsb] (\n" . Dumper(@bankch_lsb) . ')' if FALSE;
        output(@bankch_lsb);
        my @pgmch = (PGMCHANGE(), $flags, $tag, $queue,
            $time, $myself, $dest, [$channel, 0, 0, 0, 0, $program1]);
        # Start the new bank at program 0 (first program):
        output(@pgmch);
say("sending bank/LSB [$lsb]", @bankch_lsb);
    }
    $client->_set_state(NORMAL());
}

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
        croak "Fatal error: code defect [line " . __LINE__;
    }
=cut=
# !!!!Remove this switch/case version when the above is verified.
    switch ($msb) {
        case 0 {
            $result = [63, 0]; # Pre1
        }
        case 63 {
            switch ($lsb) {
                case [0..9] { $result = [$msb, $lsb + 1]; }
                case 10 { $result = [$msb, 32]; }
                case 32 { $result = [$msb, 40]; }
                case 40 { $result = [$msb, 50]; }
                case 50 { $result = [$msb, 60]; }
                case 60 { $result = [127, 0]; }   # GM drum
            }
        }
        case 127 {
            $result = [0, 0]; # GM
        }
        else {
            croak "Fatal error: code defect [line " . __LINE__;
        }
    }
say "next_bank - result: " . Dumper($result);
=cut=
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
        croak "Fatal error: code defect [line " . __LINE__;
    }
=cut=
#!!!!!!!!!!!!!!!!!!!!
# !!!!Remove this switch/case version when the above is verified.
    switch ($msb) {
        case 0 {
            $result = [127, 0]; # GM drum
        }
        case 63 {
            switch ($lsb) {
                case 0 { $result = [0, 0]; }    # GM
                case [1..10] { $result = [$msb, $lsb - 1]; }
                case 32 { $result = [$msb, 10]; }
                case 40 { $result = [$msb, 32]; }
                case 50 { $result = [$msb, 40]; }
                case 60 { $result = [$msb, 50]; }
            }
        }
        case 127 {
            $result = [63, 60]; # Mix voice
        }
        else {
            croak "Fatal error: code defect [line " . __LINE__;
        }
    }
=cut=
    $result;
}

1;