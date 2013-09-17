package RealTime_MIDI_Event;
# MIDI (note) events to be output as a MIDI real-time message (start, stop,
# or continue)

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

    state $destinations = $self->config->destination_ports;
    # myself -> source for output calls - not expected to change:
    state $myself = $self->destination();
    state $queue = undef;
    state $time = 0;
    state $start_pitch = $self->config->filter_spec->realtime_start;
    state $stop_pitch = $self->config->filter_spec->realtime_stop;
    state $continue_pitch = $self->config->filter_spec->realtime_continue;
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my (undef, $flags, $tag,  undef, undef, undef, undef, $data) =
        @{$self->event_data};
say "dispatch [for ", ref $self, "]: self: ", Dumper($self);
say "data: ", Dumper($data);
    my (undef, $pitch) = @$data;
    my $msg_type;
    if ($pitch == $start_pitch) {
        $msg_type = START();
    } elsif ($pitch == $stop_pitch) {
        $msg_type = STOP();
    } elsif ($pitch == $continue_pitch) {
        $msg_type = CONTINUE();
    }
    for my $dest (@$destinations) {
        # Construct and send the real-time message.
#        my @msg = ($msg_type, undef, undef, undef, undef, undef, $dest, []);
#        output(@msg);
#        output($msg_type, undef, undef, undef, undef, undef, $dest, []);
my ($songpos, $postick, $postime, $syncpos) = (20, 33, 34, 39);
#SND_SEQ_EVENT_SETPOS_TICK: 33
#SND_SEQ_EVENT_SETPOS_TIME: 34
#SND_SEQ_EVENT_SONGPOS: 20
#SND_SEQ_EVENT_SYNC_POS: 39
#output($songpos, 1, 1, 1, 1, 1, $dest, [1, 1, 1, 1, 1, 1]);
#output($songpos, undef, undef, undef, undef, undef, $dest, [0, 0, 0, 0, 1, 1]);
        output($msg_type, undef, undef, undef, undef, undef, $dest, []);
    }
    $client->_set_state(NORMAL());
}

1;
