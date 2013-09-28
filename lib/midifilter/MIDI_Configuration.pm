package MIDI_Configuration;
# MIDI application configuration interface

use Mouse;
use Modern::Perl;
use File::Basename qw(basename);
use constant::boolean;


### public

# Print debugging/tracing information?
sub debug() { state $result = $ENV{MIDIDEBUG}; $result; }


# The name of the running process
sub application_name {
    basename($0);
}

# ALSA MIDI ports from which to connect for input
sub source_ports {}

# ALSA MIDI ports to which MIDI events are to be sent
sub destination_ports {}

# Filtering-logic specifications
sub filter_spec {}

# Has program-change sample mode been canceled?
sub program_change_sample_canceled {}

1;
