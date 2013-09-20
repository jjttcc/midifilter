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
use GeneralMidi;
use Announcer;
use threads;
use threads::shared;

my $can_use_threads = eval 'use threads; 1';

extends 'MIDI_Event';

my $cancel_program_change_sampling :shared = FALSE;
my $stop_program_change_sampling :shared = FALSE;

#####  Interface implementation (public)

sub dispatch {
    my ($self, $client) = @_;

    if (not $can_use_threads) {
        say "Warning: threads are not available, which means the " .
            "program_change_sample\nfeature cannot be used";
        $client->_set_state(NORMAL());
        return;
    }
    $client->_set_state(NORMAL());
    my $continued = ($stop_program_change_sampling and
        not $self->config->program_change_sample_stopped);
    $cancel_program_change_sampling =
        $self->config->program_change_sample_canceled;
    $stop_program_change_sampling =
        $self->config->program_change_sample_stopped;
    if (not $continued and not $cancel_program_change_sampling and
            not $stop_program_change_sampling) {
        my $thread = threads->create(\&handle_program_change_mode, $self);
        $thread->detach();
    }
}


#####  Implementation (non-public)

sub pause {
    my ($self, $seconds) = @_;

    my $slept = 0;
    # Sleep 1 second at a time as long as we've not slept enough and
    # conditions require it.
    while ($slept < $seconds and not $cancel_program_change_sampling or
            $stop_program_change_sampling) {
        sleep 1;
        if (not $stop_program_change_sampling) {
            ++$slept;
        } else {
            # If $stop_program_change_sampling, don't increment $slept, so
            # that this loop continues until $stop_program_change_sampling
            # gets reset to FALSE in the main thread.
        }
    }
}

sub handle_program_change_mode {
    my ($self) = @_;

    state $announcer = $self->config->filter_spec->announcer;
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
    while (not $cancel_program_change_sampling and $current_program != 128) {
        my $instrument = $instrument_name_for->{$current_program};
        $announcer->announce("Patch $current_program: $instrument");
        for my $dest (@$destinations) {
            output(PGMCHANGE(), $flags, $tag, $queue, $time, $myself, $dest,
                [$channel, 0, 0, 0, 0, $current_program]);
        }
        ++$current_program;
        $self->pause($sleep_seconds);
    }
    $current_program = 0;
}

1;

