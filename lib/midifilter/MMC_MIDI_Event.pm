package MMC_MIDI_Event;
# MIDI (note) events to be output as a MIDI Machine Control event

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

    # (Optimization: set @destinations, $filter_spec only once:)
    state $destinations = $self->config->destination_ports;
    state $filter_spec = $self->config->filter_spec;
    # myself -> source for output calls - not expected to change:
    state $myself = $self->destination();
    state $queue = undef;
    state $time = 0;
state $announcer = $filter_spec->announcer;
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my (undef, $flags, $tag,  undef, undef, undef, undef, $data) =
        @{$self->event_data};
    my (undef, $pitch) = @$data;
    my $cmd = $filter_spec->mmc_command->{$pitch};
say "MMC_MIDI_Event - cmd: ", Dumper($cmd);
    my $mmc_cmd = $self->mmc_data($cmd);
my $foo = "MMC ". $cmd->[0]; say "foo: $foo";
    $announcer->announce("MMC ". $cmd->[0]);
    for my $dest (@$destinations) {
        output(SND_SEQ_EVENT_SYSEX(), $flags, $tag, $queue, $time, $myself,
            $dest, $mmc_cmd);
    }
    $client->set_state(NORMAL());
}


#####  Implementation (non-public)

sub mmc_data {
    my ($self, $mmctype_devid) = @_;
    my $channel = 0;    #!!!!Check: channel doesn't matter, right?!!!!
    state $mmc_cmd_for = mmc_command_from_name();
    my $cmdnum = $mmc_cmd_for->{$mmctype_devid->[0]};
    # Create array containing valid MMC "byte" sequence
say "devid: ", $mmctype_devid->[1];
say "hex devid: ", hex('0x' . $mmctype_devid->[1]);
    my @data_array = (hex('7f'), hex(sprintf("%x", $mmctype_devid->[1])),
        hex('06'), $cmdnum);
    my $mmc_string = '';
    # Convert the array to a string.
    for my $x (@data_array) {
say "x, chr x: ", $x, ", '", chr $x, "'";
        $mmc_string .= chr $x;
    }
say "data_array: ", Dumper(\@data_array);
say "mmc_string: ", Dumper($mmc_string);
    my $result = MIDI::ALSA::sysex($channel, $mmc_string);
say 'result ', Dumper($result);
    $result;
}

sub mmc_command_from_name {
    {
        'stop'          => hex('01'),
        'play'          => hex('03'),   # actually - deferred play (skip play)
        'fast_forward'  => hex('04'),
        'rewind'        => hex('05'),
        'record_strobe' => hex('06'),
        'record_exit'   => hex('07'),
        'record_pause'  => hex('08'),
        'pause'         => hex('09'),
        'eject'         => hex('0a'),
        'chase'         => hex('0b'),
        'mmc_reset'     => hex('0d'),
        'write'         => hex('40'),
        'goto'          => hex('44'),
        'shuttle'       => hex('47'),
    };
}

1;
