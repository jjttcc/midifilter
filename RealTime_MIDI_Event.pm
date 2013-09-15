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

    state $destinations = $self->destinations;
    # myself -> source for output calls - not expected to change:
    state $myself = $self->destination();
    state $queue = undef;
    state $time = 0;
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my (undef, $flags, $tag,  undef, undef, undef, undef, $data) =
        @{$self->event_data};
say "dispatch [for ", ref $self, "]: self: ", Dumper($self);
say "data: ", Dumper($data);
    my (undef, $pitch) = @$data;
    my $msg_type;
    if ($pitch == RT_START()) {
        $msg_type = START();
    } elsif ($pitch == RT_STOP()) {
        $msg_type = STOP();
    } elsif ($pitch == RT_CONT()) {
        $msg_type = CONTINUE();
    }
    for my $dest (@$destinations) {
        # Construct and send the real-time message.
        my @msg = ($msg_type, undef, undef, undef, undef, undef, $dest, []);
        output(@msg);
    }
    $client->_set_state(NORMAL());
}

1;
