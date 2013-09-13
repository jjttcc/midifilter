package MIDI_EventStream;
# A stream of MIDI events input from a source, to be dispatched to one or more
# destinations

use Mouse;
use Modern::Perl;
use constant::boolean;
use Data::Dumper;
use MIDI_EventFilter;

use MIDI_Facilities;

# Configuration data
has config => (
    is      => 'ro',
    isa     => 'MIDI_Configuration',
);

# Prepare and then enter event loop to input, filter, and dispatch MIDI events.
sub process {
    my ($self) = @_;
say "verb: ", $self->config->verbose;
say "srcprts: ", Dumper(@{$self->config->source_ports});
    for my $port (@{$self->config->source_ports}) {
        connectfrom(1, $port->[0], $port->[1]);
say 'connectfrom(1, ', $port->[0], ', ', $port->[1], ')';
    }
    for my $port (@{$self->config->destination_ports}) {
        connectto(1, $port->[0], $port->[1]);
say 'connectto(1, ', $port->[0], ', ', $port->[1], ')';
    }

    $self->_run_event_loop();
}


### private

sub _run_event_loop {
    my ($self) = @_;

    my $filter = MIDI_EventFilter->new(config => $self->config);
    while (1) {
        $filter->dispatch_next_event();
    }
}

1;
