package MIDI_EventStream;
# A stream of MIDI events input from a source, to be dispatched to one or more
# destinations

use Mouse;
use Modern::Perl;
use constant::boolean;
use feature 'state';
use Data::Dumper;
use Switch; #!!!!!!remove if switch statement goes away!!!!
use MIDI_EventFilter;

with 'MIDI_Facilities';

# ALSA MIDI ports from which to connect for input
has source_ports => (
    is      => 'ro',
    isa     => 'ArrayRef[ArrayRef[Str]]',
);

# ALSA MIDI ports to which MIDI events are to be sent
has destination_ports => (
    is      => 'ro',
    isa     => 'ArrayRef[ArrayRef[Str]]',
);

# Print debugging/tracing information?
has config => (
    is      => 'ro',  # private
    isa     => 'AppConfiguration',
);

# Prepare and then enter event loop to input, filter, and dispatch MIDI events.
sub process {
    my ($self) = @_;
say "verb: ", $self->config->verbose;
    for my $port (@{$self->source_ports}) {
        connectfrom(1, $port->[0], $port->[1]);
    }
    for my $port (@{$self->destination_ports}) {
        connectto(1, $port->[0], $port->[1]);
    }

    $self->_run_event_loop();
}


### private

sub _run_event_loop {
    my ($self) = @_;
# !!!!!not used - remove:    my $bank = [0, 0];
    my $current_bank = [0, 0];
    my $evcount = 0;
    my $cmd_override = FALSE;
    my $program_change = FALSE;
    my $pc_top_range = FALSE;
    my $myself;

    say "ctlr: " . SND_SEQ_EVENT_CONTROLLER();
    say "chnlvol: " . $MIDI_Facilities::CHANNEL_VOLUME;

    my $destinations = $self->destination_ports;
    my $filter = MIDI_EventFilter->new();
    while (0) { # !!!!reminder: when ready: 0 -> 1
        $filter->retrieve_next_event();
# !!!design choice 1:
#        my $event = $filter->current_event();
#        $event->dispatch();
# !!!design choice 2:
        $filter->dispatch_current_event();
    }

exit 0; #!!!!!!!!!!!!!!!!!!!
# !!!!!!!!!!!refactoring needed!!!!!!!!!!!!!
    while (1) {
        my @alsaevent = input();
        ++$evcount;
        my ($type, $flags, $tag, $queue, $time, $source, $destination,
            $data) = @alsaevent;
        if (not defined $myself) {
            $myself = $destination;
        }
        my $repl_data = $data;
        switch ($type) {
            case [SND_SEQ_EVENT_NOTEON(), SND_SEQ_EVENT_NOTEOFF()] {
                my ($channel, $pitch, $velocity, undef, $duration) = @$data;
    say "got note " . ($velocity == 0? 'OFF ': 'ON ') .
    "event [$evcount]: " . Dumper(\@alsaevent) if $self->config->verbose;
                my $note = Music::Note->new($pitch, 'midinum');
    say "note: " . $note->format('ISO') if $self->config->verbose;
    say "source, dest: " . Dumper($source) . ", " .
    Dumper($destination) if $self->config->verbose;
                if ($cmd_override and $pitch >= $MIDI_Facilities::CTL_START) {
                    if ($velocity == 0) {   # NOTE-OFF
                        $cmd_override = FALSE;
                        if ($pitch == $MIDI_Facilities::C8 or
                                $pitch == $MIDI_Facilities::B7) {
                            $program_change = TRUE;
                            if ($pitch == $MIDI_Facilities::B7) {
                                $pc_top_range = TRUE;
                            }
                        } elsif ($pitch == $MIDI_Facilities::Bb7) {
                            $current_bank = $self->change_bank_select(TRUE, $current_bank,
                                \@alsaevent, $myself, $destinations);
                        } elsif ($pitch == $MIDI_Facilities::A7) {
                            $current_bank = $self->change_bank_select(FALSE, $current_bank,
                                \@alsaevent, $myself, $destinations);
                        }
                    } else {
                        # $velocity != 0: NOTE-ON
                        # no-op when $cmd_override - i.e., throw the event away.
                    }
                } elsif ($program_change) {
                    if ($velocity == 0) {   # NOTE-OFF
                        # (program change was signalled with the previous event.)
                        $program_change = FALSE;
                        my $program = $pitch; # i.e., note-on pitch -> new program#
                        if (not $pc_top_range) {
                            $program -= $MIDI_Facilities::LOWEST_88KEY_PITCH;  # e.g., 21 => 0
                        } else {
                            $program += (127 - $MIDI_Facilities::HIGHEST_88KEY_PITCH); # 108 => 127
                        }
                        $pc_top_range = FALSE;
                        $self->change_program($flags, $tag, $queue, $time, $myself,
                            $destinations, [$channel, 0, 0, 0, 0, $program]);
                    } else {
                        # $velocity != 0: NOTE-ON
                        # no-op when $program_change - i.e., throw the event away.
                    }
                } else {
                    # Pass on the received note event.
                    for my $dest (@$destinations) {
                        output($type, $flags, $tag, $queue, $time, $myself,
                            $dest, $repl_data);
                    }
                }
            }
            case SND_SEQ_EVENT_CONTROLLER() {
    say STDERR "got a control change event [$evcount]: " .
    Dumper(\@alsaevent) if $self->config->verbose;
                my ($channel, undef, undef, undef, $param, $value) = @$data;
                if ($param == $MIDI_Facilities::CHANNEL_VOLUME) {
                    # control-change/channel-volume is (for now, at least)
                    # hard-coded to signal a change to command-override status.
                    $cmd_override = TRUE;
                } else {
                    for my $dest (@$destinations) {
                        # Pass on the received control change message.
                        output($type, $flags, $tag, $queue, $time, $myself,
                            $dest, $repl_data);
                    }
                }
            }
            else {
    say STDERR "got some other event [$evcount]: " .
    Dumper(\@alsaevent) if $self->config->verbose;
                    for my $dest (@$destinations) {
                        # Pass on the received event/message.
                        output($type, $flags, $tag, $queue, $time, $myself,
                            $dest, $repl_data);
                    }
            }
        }
    }
}

####################

# Next valid bank-select [MSB, LSB] value based on $currbank
# [Specific to Motif/XS]
sub next_bank {
    my ($self, $currbank) = @_;
    my $result = [];
    my ($msb, $lsb) = @$currbank;
    # For Motif/XS - only used bank-select MSB of 0, 63, or 127.
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
            croak($self->config->program_name .
                ": Fatal error: code defect [line " . __LINE__);
        }
    }
say "next_bank - result: " . Dumper($result);
    $result;
}

# Previous valid bank-select [MSB, LSB] value based on $currbank
# [Specific to Motif/XS]
sub previous_bank {
    my ($self, $currbank) = @_;
    my $result = [];
    my ($msb, $lsb) = @$currbank;
    # For Motif/XS - only used bank-select MSB of 0, 63, or 127.
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
            croak($self->config->program_name .
                ": Fatal error: code defect [line " . __LINE__);
        }
    }
    $result;
}

# Send the specified program change message to the specified destinations.
sub change_program {
    my ($self, $flags, $tag, $queue, $time, $source, $destinations, $data) = @_;

    if ($self->config->verbose) {
        my $program = @$data[$#$data];
        say "sending program [$program] change (\n" . Dumper(
            $source, $destinations, $data) . ')';
    }
    for my $dest (@$destinations) {
debug('sending program change', $source, $dest, $data);
        output(SND_SEQ_EVENT_PGMCHANGE(), $flags, $tag, $queue, $time, $source,
            $dest, $data);
    }
}

# Change the bank selection (upward, if $up; otherwise, downward) and send
# the selection with the appropriate MIDI CC message.  Return the new bank
# values ([msb, lsb]).
sub change_bank_select {
    my ($self, $up, $currbank, $event, $source, $destinations) = @_;
    my (undef, $flags, $tag, $queue, $time, undef, undef, $data) = @$event;
    if (not defined $source or not defined $destinations) {
        croak($self->config->program_name .
            ": \$source and/or \$destinations not set");
    }
    my ($channel) = @$data;
    my $first_program = 0;
    my $result;
    if ($up) {
        $result = $self->next_bank($currbank);
    } else {
        $result = $self->previous_bank($currbank);
    }
    for my $dest (@$destinations) {
        my ($msb, $lsb) = @$result;
        my @bankch_msb = (SND_SEQ_EVENT_CONTROLLER(), $flags, $tag,
            $queue, $time, $source, $dest,
            [$channel, 0, 0, 0, $MIDI_Facilities::BANKMSB_SELECT, $msb]);
say "sending bank/MSB [$msb] (\n" . Dumper(@bankch_msb) . ')' if $self->config->verbose;
        my @pgmch = (SND_SEQ_EVENT_PGMCHANGE(), $flags, $tag, $queue,
            $time, $source, $dest, [$channel, 0, 0, 0, 0, $first_program]);
        output(@bankch_msb);
debug("sending bank/MSB [$msb]", @bankch_msb);
        my @bankch_lsb = (SND_SEQ_EVENT_CONTROLLER(), $flags, $tag,
            $queue, $time, $source, $dest,
            [$channel, 0, 0, 0, $MIDI_Facilities::BANKLSB_SELECT, $lsb]);
say "sending bank/LSB [$lsb] (\n" . Dumper(@bankch_lsb) . ')' if $self->config->verbose;
        output(@bankch_lsb);
        # Start the new bank at program 0 (first program):
        output(@pgmch);
debug("sending bank/LSB [$lsb]", @bankch_lsb);
    }
    $result;
}

sub debug {
    my ($msg, @args) = @_;
    say "$msg:";
    print Dumper(@args);
}

1;
