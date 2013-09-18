package FilterSpecification;
# Specifications for MIDI event filtering logic

use Mouse;
use Modern::Perl;
use Data::Dumper;
use Carp;


###  Access

# The pitch value of the top note on the keyboard device being used
has top_note_value => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_top_note_value',
    init_arg => undef,
);

# The pitch value of the bottom note on the keyboard device being used
has bottom_note_value => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_bottom_note_value',
    init_arg => undef,
);

# The pitch value that indicates that the next note-off event will have its
# pitch used as the program-change patch number - high meaning this pitch
# will be added to so that 108 becomes 127
has program_change_high => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_program_change_high',
    init_arg => undef,
);

# The pitch value that indicates that the next note-off event will have its
# pitch used as the program-change patch number - low meaning this pitch
# will be subtracted from so that 21 becomes 0
has program_change_low => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_program_change_low',
    init_arg => undef,
);

# The pitch value that indicates that a bank-select is to be sent, for which
# the bank MSB/LSB values will be the next values relative to the current bank
has bank_select_up => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_bank_select_up',
    init_arg => undef,
);

# The pitch value that indicates that a bank-select is to be sent, for which
# the bank MSB/LSB values will be the previous values relative to the
# current bank
has bank_select_down => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_bank_select_down',
    init_arg => undef,
);

# External commands to be executed - hashref keyed by pitch value
has external_commands => (
    is       => 'ro',
    isa      => 'HashRef[Str]',
    default  => sub { {} },
    init_arg => undef,
);

# Pitch indicating that real-time START be sent
has realtime_start => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_realtime_start',
    init_arg => undef,
);

# Pitch indicating that real-time STOP be sent
has realtime_stop => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_realtime_stop',
    init_arg => undef,
);

# Pitch indicating that real-time CONTINUE be sent
has realtime_continue => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_realtime_continue',
    init_arg => undef,
);

# Control change type (numeric value - decimal) to trigger override mode
has override_cc_control_number => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_override_cc_control_number',
    default  => 7,
    init_arg => undef,
);

###  Basic operations

# Parse and process the specified $lines (ArrayRef) and make the result
# available via the public interface
sub process {
    my ($self, $lines) = @_;
    if (not defined $lines) { croak "process: argument not valid"; }
    my @result = ([], []);
#Readonly::Scalar my $FROM => 0;
#Readonly::Scalar my $TO   => 1;

    my $externals = $self->external_commands;
    for my $line (@$lines) {
        # (Example valid line: 'to: 16, 0')
        if ($line =~ /^([a-z_]+:?)\s*(\d+)\s*$/) {
            my ($tag, $value) = ($1, $2);
            if ($tag =~ /program[_-]change[_-]high:?/) {
                $self->_set_program_change_high($value);
            } elsif ($tag =~ /program[_-]change[_-]low:?/) {
                $self->_set_program_change_low($value);
            } elsif ($tag =~ /bank[_-]select[_-]up:?/) {
                $self->_set_bank_select_up($value);
            } elsif ($tag =~ /bank[_-]select[_-]down:?/) {
                $self->_set_bank_select_down($value);
            } elsif ($tag =~ /real[_-]?time[_-]start:?/) {
                $self->_set_realtime_start($value);
            } elsif ($tag =~ /real[_-]?time[_-]stop:?/) {
                $self->_set_realtime_stop($value);
            } elsif ($tag =~ /real[_-]?time[_-]continue:?/) {
                $self->_set_realtime_continue($value);
            } elsif ($tag =~ /override[_-]?cc[_-]?control[_-]?number:?/) {
                $self->_set_override_cc_control_number($value);
            } elsif ($tag =~ /top[_-]?note:?/) {
                $self->_set_top_note_value($value);
            } elsif ($tag =~ /bottom[_-]?note:?/) {
                $self->_set_bottom_note_value($value);
            } else {
                carp "Invalid configuration line: $line";
            }
        }
        if ($line =~ /^([a-z_]+:?)\s*(\d+)\s+(.*)$/) {
            my ($tag, $value, $command) = ($1, $2, $3);
            if ($tag =~ /external[_-]cmd:?/) {
                $externals->{$value} = $command;
            }
        }
    }
    @result;
}

1;

