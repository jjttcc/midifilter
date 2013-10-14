package FilterSpecification;
# Specifications for MIDI event filtering logic

use Mouse;
use Modern::Perl;
use constant::boolean;
use Data::Dumper;
use Carp;
use Announcer;
use TranspositionSpecification;


###  Access

# The pitch value of the top note on the keyboard device being used
has top_note_value => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { 96 },
    writer   => '_set_top_note_value',
    init_arg => undef,
);

# The pitch value of the bottom note on the keyboard device being used
has bottom_note_value => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { 36 },
    writer   => '_set_bottom_note_value',
    init_arg => undef,
);

# The pitch value that indicates that the next note-off event will have its
# pitch used as the program-change patch number - high meaning this pitch
# will be added to so that 108 becomes 127
has program_change_high => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { -1 },     # (default to 'unset')
    writer   => '_set_program_change_high',
    init_arg => undef,
);

# The pitch value that indicates that the next note-off event will have its
# pitch used as the program-change patch number - low meaning this pitch
# will be subtracted from so that 21 becomes 0
has program_change_low => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { -1 },     # (default to 'unset')
    writer   => '_set_program_change_low',
    init_arg => undef,
);

# The pitch value that indicates that a bank-select is to be sent, for which
# the bank MSB/LSB values will be the next values relative to the current bank
has bank_select_up => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { -1 },     # (default to 'unset')
    writer   => '_set_bank_select_up',
    init_arg => undef,
);

# The pitch value that indicates that a bank-select is to be sent, for which
# the bank MSB/LSB values will be the previous values relative to the
# current bank
has bank_select_down => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { -1 },     # (default to 'unset')
    writer   => '_set_bank_select_down',
    init_arg => undef,
);

# The pitch value that indicates that the next note-off event will trigger
# program-change sampling mode
has program_change_sample => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { -1 },     # (default to 'unset')
    writer   => '_set_program_change_sample',
    init_arg => undef,
);

# The number of seconds for each "patch sampling" period when in
# program-change sampling mode
has program_change_sample_seconds => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_set_program_change_sample_seconds',
    default  => sub { 10 },
    init_arg => undef,
);

# The pitch value that, when in program-change sampling mode, indicates that
# the mode is to be canceled
has cancel_program_change_sample => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { -1 },     # (default to 'unset')
    writer   => '_set_cancel_program_change_sample',
    init_arg => undef,
);

# The pitch value that, when in program-change sampling mode, indicates that
# the mode is to be stopped
has stop_program_change_sample => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { -1 },     # (default to 'unset')
    writer   => '_set_stop_program_change_sample',
    init_arg => undef,
);

# The pitch value that, when in program-change sampling mode, indicates that
# the mode is to be continued
has continue_program_change_sample => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { -1 },     # (default to 'unset')
    writer   => '_set_continue_program_change_sample',
    init_arg => undef,
);

# Set of MIDI machine control specifications, keyed by pitch:
# mmc_command->{pitch} => [<cmd-type-tag>, <device-id>]
has mmc_command => (
    is       => 'ro',
    isa      => 'HashRef[ArrayRef]',
    default  => sub { {} },
    init_arg => undef,
);

# Set of configured transposition specifications
has transposition_specs => (
    is => 'ro',
    isa => 'HashRef[TranspositionSpecification]',
    default => sub { {} },
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
    default  => sub { -1 },     # (default to 'unset')
    writer   => '_set_realtime_start',
    init_arg => undef,
);

# Pitch indicating that real-time STOP be sent
has realtime_stop => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { -1 },     # (default to 'unset')
    writer   => '_set_realtime_stop',
    init_arg => undef,
);

# Pitch indicating that real-time CONTINUE be sent
has realtime_continue => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { -1 },     # (default to 'unset')
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

# Path of program to execute for "announcements"
has announcer => (
    is       => 'ro',
    writer   => '_set_announcer',
    # (Use gets a very minimal "announcer" if it is not specified.)
    default  => sub { Announcer->new(announce_prog => 'cat') },
    init_arg => undef,
);

sub non_pitch_spec {
    {
        'override_cc_control_number'    => TRUE,
        'program_change_sample_seconds' => TRUE,
    }
}

# Have any transpositions been configured?
sub transpositions_configured {
    my ($self) = @_;
    my $result = FALSE;
    if (%{$self->transposition_specs}) {
        $result = TRUE;
    }
    $result;
}

###  Basic operations

# Parse and process the specified $lines (ArrayRef) and make the result
# available via the public interface
sub process {
    my ($self, $lines) = @_;
    if (not defined $lines) { croak "process: argument 'lines' not valid"; }
    my @result = ([], []);

    for my $line (@$lines) {
        if ($line =~ /^([a-z_]+:?)\s*(\d+)\s*$/) {
            # e.g.: 'real_time_stop: 34'
            my ($tag, $value) = ($1, $2);
            $self->process_one_numeric_argument($tag, $value, $line);
        } elsif ($line =~ /^([a-z_]+:?)\s*(\w+)$/) {
            # e.g.: 'announcer: program'
            my ($tag, $value) = ($1, $2);
            if ($tag =~ /\bannouncer:?\b/) {
                $self->_set_announcer(Announcer->new(announce_prog => $value));
            }
        } elsif ($line =~ /^([a-z_]+:?)\s*(\d+)\s+(.*)$/) {
            # e.g.: 'external_cmd: 21 echo test'
            my ($tag, $value, $param) = ($1, $2, $3);
            $self->process_numeric_argument_with_parameter($tag, $value,
                $param, $line);
        }
    }
    @result;
}


#####  Implementation (non-public)

# Set the configuration parameter specified by $tag using the specified
# numeric value ($value) and parameter ($param).
sub process_numeric_argument_with_parameter {
    my ($self, $tag, $value, $param, $current_line) = @_;

    if ($tag =~ /external[_-]cmd:?/) {
        my $externals = $self->external_commands;
        $externals->{$value} = $param;
    } elsif ($tag =~ /transpose[_-]spec:?/) {
        if ($param =~ /(\d+)\S+?(\d+)\s+([+-]?\d+)/) {
            my ($bottom, $top, $half_steps) = ($1, $2, int($3));
            $self->transposition_specs->{$value} =
                TranspositionSpecification->new(
                bottom_pitch => $bottom, top_pitch => $top,
                steps => $half_steps);
        } else {
            carp "Invalid transpose specification: $current_line";
        }
    } elsif ($tag =~ /mmc[_-]([[:alpha:]_]+):?/) {
        my $mmctype = $1;
        $self->_add_mmc_command($mmctype, $value, $param);
    }
}

# Set the configuration parameter specified by $tag using the numeric $value.
sub process_one_numeric_argument {
    my ($self, $tag, $value, $current_line) = @_;

    if ($tag =~ /\bprogram[_-]change[_-]high:?\b/) {
        $self->_set_program_change_high($value);
    } elsif ($tag =~ /\bprogram[_-]change[_-]low:?\b/) {
        $self->_set_program_change_low($value);
    } elsif ($tag =~ /\bbank[_-]select[_-]up:?\b/) {
        $self->_set_bank_select_up($value);
    } elsif ($tag =~ /\bbank[_-]select[_-]down:?\b/) {
        $self->_set_bank_select_down($value);
    } elsif ($tag =~ /\breal[_-]?time[_-]start:?\b/) {
        $self->_set_realtime_start($value);
    } elsif ($tag =~ /\breal[_-]?time[_-]stop:?\b/) {
        $self->_set_realtime_stop($value);
    } elsif ($tag =~ /\breal[_-]?time[_-]continue:?\b/) {
        $self->_set_realtime_continue($value);
    } elsif ($tag =~ /\boverride[_-]?cc[_-]?control[_-]?number:?\b/) {
        $self->_set_override_cc_control_number($value);
    } elsif ($tag =~ /\btop[_-]?note:?\b/) {
        $self->_set_top_note_value($value);
    } elsif ($tag =~ /\bbottom[_-]?note:?\b/) {
        $self->_set_bottom_note_value($value);
    } elsif ($tag =~ /\bprogram[_-]change[_-]sample:?\b/) {
        $self->_set_program_change_sample($value);
    } elsif ($tag =~ /\bprogram[_-]change[_-]sample[_-]seconds:?\b/) {
        if ($value == 0) { $value = 1; }    # 0 is not allowed
        $self->_set_program_change_sample_seconds($value);
    } elsif ($tag =~ /\bcancel_program[_-]change[_-]sample:?\b/) {
        $self->_set_cancel_program_change_sample($value);
    } elsif ($tag =~ /\bstop_program[_-]change[_-]sample:?\b/) {
        $self->_set_stop_program_change_sample($value);
    } elsif ($tag =~ /\bcontinue_program[_-]change[_-]sample:?\b/) {
        $self->_set_continue_program_change_sample($value);
    } else {
        carp "Invalid configuration line: $current_line";
    }
}

sub _add_mmc_command {
    my ($self, $mmctype, $pitch, $device_id) = @_;
    my $mmc_tbl = $self->mmc_command;
    if (not defined $mmc_tbl) {
        confess "Code defect (__LINE__, __FILE__): mmc_command not defined";
    }
    my $type_and_devid = [$mmctype, int($device_id)];
    $mmc_tbl->{$pitch} = $type_and_devid;
}

1;

