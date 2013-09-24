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
use Announcer;


extends 'MIDI_Event';


#####  Interface implementation (public)

sub dispatch {
    my ($self, $client) = @_;
    state $commands = $self->config->filter_spec->external_commands;
    state $announcer = $self->config->filter_spec->announcer;
    my $data = $self->data;
    my (undef, $pitch) = @$data;
    my $cmd = $commands->{$pitch};
    if ($cmd) {
        if ($cmd eq TERMINATE_CMD()) {
            exit 0;
        } elsif ($cmd eq REPORT_CFG_CMD()) {
            my $report = $self->config->filter_spec_report;
            $announcer->announce($report);
        } else {
            if ($cmd !~ /&\s$/) { $cmd .= ' &'; }
            system($cmd);
        }
    }
    $client->_set_state(NORMAL());
}


1;
