package ProgramChangeSample_MIDI_Event;
# something-or-other events to be generated and sent as the result or
# program-change-sampling mode

use Mouse;
use Modern::Perl;
use Carp;
use Carp::Always;
use Data::Dumper;
use feature qw(state);
use constant::boolean;
use MIDI_Facilities;
use threads;
use threads::shared;

my $can_use_threads = eval 'use threads; 1';

extends 'MIDI_Event';

my $stop_program_change_sampling :shared = FALSE;

#####  Interface implementation (public)

sub dispatch {
    my ($self, $client) = @_;

#    my $config :shared = $self->config;
    if (not $can_use_threads) {
        say "Warning: threads are not available, which means the " .
            "program_change_sample\nfeature cannot be used";
        $client->_set_state(NORMAL());
        return;
    }
    $client->_set_state(NORMAL());
say "[PCS] pcsc: ", $self->config->program_change_sample_canceled;
    if ($self->config->program_change_sample_canceled) {
        # User has ordered PC sampling canceled - force thread to end:
        $stop_program_change_sampling = TRUE;
    } else {
        my $thread = threads->create(\&handle_program_change_mode, $self);
        $thread->detach();
    }
}


#####  Implementation (non-public)

sub handle_program_change_mode {
    my ($self) = @_;

say "handle_program_change_mode called";
    my $filter_spec = $self->config->filter_spec;
    my $sleep_seconds = $filter_spec->program_change_sample_seconds;
    my $current_program = 0;
    my $sampling_seconds = $filter_spec->program_change_sample_seconds;
    my $destinations = $self->config->destination_ports;
    # myself -> source for output calls - not expected to change:
    my $myself = $self->destination();
    my $queue = undef;
    my $time = 0;
    # (Assume: queue, time, source, destination [undefs] are not needed:)
    my (undef, $flags, $tag,  undef, undef, undef, undef, $data) =
        @{$self->event_data};
    my ($channel, $pitch) = @$data;
say "sampling_seconds: $sampling_seconds";
    while (not $stop_program_change_sampling and $current_program != 128) {
say "current_program: $current_program [tid: ", threads->self->tid(), ']';
        for my $dest (@$destinations) {
            output(PGMCHANGE(), $flags, $tag, $queue, $time, $myself, $dest,
                [$channel, 0, 0, 0, 0, $current_program]);
        }
        ++$current_program;
        sleep $sleep_seconds;
    }
    if ($stop_program_change_sampling) {
        # reset/clean-up
        $stop_program_change_sampling = FALSE;
    }
    $current_program = 0;
}

1;

