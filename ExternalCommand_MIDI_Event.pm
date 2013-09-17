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
say "commands: ", Dumper($commands);
    my $data = $self->data;
    # Do we need the channel?
    my ($channel, $pitch) = @$data;
    my $cmd = $commands->{$pitch};
    if ($cmd) {
        if ($cmd eq TERMINATE_CMD()) {
            exit 0;
        }
        ## !!!If we're not going to use fork/exec:
        if ($cmd !~ /&\s$/) { $cmd .= ' &'; }
say "cmd: ", Dumper($cmd);
        system($cmd);
    }
    $client->_set_state(NORMAL());
}

sub old___dispatch {
    my ($self, $client) = @_;

say "dispatch [for ", ref $self, "]: self: ", Dumper($self);
    my $data = $self->data;
say "data: ", Dumper($data);
    # Do we need the channel?
    my ($channel, $pitch) = @$data;
    # !!!Dummy/demo (command needs to be configured externally)
    my %command_map = (
        21 => 'pkill -CONT -f rosegarden',
        22 => 'pkill -STOP -f rosegarden',
        23 => 'echo This is a test|write $USER',
        24 => 'date',
        25 => 'espeak "This is a test"',
    );
    my $cmd = $command_map{$pitch} . '&';
say "COMMAND: $cmd";
    if ($cmd) {
        # !!!fork/exec might be better.
        system($cmd);
    }
    $client->_set_state(NORMAL());
}

1;
