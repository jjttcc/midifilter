package ExternalCommand_MIDI_Event;
# MIDI (note) events whose data will be used to govern the execution of an
# external command

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
    state $commands = $self->config->filter_spec->external_commands;
    my $data = $self->data;
    # Do we need the channel?
    my ($channel, $pitch) = @$data;
    my $cmd = $commands->{$pitch};
    if ($cmd) {
        if ($cmd eq TERMINATE_CMD()) {
            exit 0;
        }
        if ($cmd !~ /&\s$/) { $cmd .= ' &'; }
        system($cmd);
    }
    $client->_set_state(NORMAL());
}


1;
