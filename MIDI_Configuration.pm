package MIDI_Configuration;
# MIDI application configuration interface

use Mouse;
use Modern::Perl;
use File::Basename qw(basename);
use constant::boolean;


### public

# Print debugging/tracing information?
sub verbose {
    defined $ENV{VERBOSE};
}

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

1;
