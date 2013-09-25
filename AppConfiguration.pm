package AppConfiguration;
# midifilter application configuration facilities

use Mouse;
use Modern::Perl;
use constant::boolean;
use File::Basename qw(basename);
use Readonly;
use Music::Note;
use Carp;
use Data::Dumper;

use FilterSpecification;

extends 'MIDI_Configuration';

#####  Public interface

###  Access

# MIDI event stream
has midi_stream => (
    is      => 'ro',
    isa     => 'MIDI_EventStream',
    writer  => '_set_midi_stream',
);

# Name of the running program
has application_name => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { MIDI_Configuration::application_name(); }
);

# ALSA MIDI ports from which to connect for input
has source_ports => (
    is      => 'ro',
    isa     => 'ArrayRef[ArrayRef[Str]]',
    writer  => '_set_source_ports',
    init_arg => undef,  # i.e., cannot be supplied in 'new' method
);

# ALSA MIDI ports to which MIDI events are to be sent
has destination_ports => (
    is      => 'ro',
    isa     => 'ArrayRef[ArrayRef[Str]]',
    writer  => '_set_destination_ports',
    init_arg => undef,  # i.e., cannot be supplied in 'new' method
);

# Specifications for filtering logic
has filter_spec => (
    is       => 'ro',
    isa      => 'FilterSpecification',
    writer   => '_set_filter_spec',
    init_arg => undef,  # not to be supplied in 'new'
);

has program_change_sample_canceled => (
    is       => 'rw',
    isa      => 'Bool',
    default  => FALSE,
    init_arg => undef,  # not to be supplied in 'new'
);

# Has program-change sample mode been stopped?
has program_change_sample_stopped => (
    is       => 'rw',
    isa      => 'Bool',
    default  => FALSE,
    init_arg => undef,  # not to be supplied in 'new'
);


# Informally-formatted report on the current settings of 'filter_spec'
sub filter_spec_report {
    my ($self) = @_;
    my $result = '';
    my $fs_meta = $self->filter_spec->meta;
    my @attrs = $fs_meta->get_all_attributes;
    my %name_for = map {
        $_->get_value($self->filter_spec) => $_->name;
    } @attrs;
    for my $value (sort {
        # Sort by numeric value, ascending (non-numbers/strings after numbers).
        if ($a !~ /^\d+$/) { 1 } elsif ($b !~ /^\d+$/) { -1 } else {
            $a <=> $b
        }
    } keys %name_for) {
        my $name = $name_for{$value};
        if ($name eq 'announcer') {
            next;   # Skip 'announcer' attribute.
        }
        if (ref $value eq 'HASH') {
            $result .= $name . ":\n";
            for my $k (keys %$value) {
                my $v = $value->{$k};
                $result .= '  ' . $k . ': ' . $v . "\n";
            }
        } else {
            $result .= $name . ': ' . $value;
            if (not $self->filter_spec->non_pitch_spec->{$name}) {
                # $value is supposedly a pitch.
                my $note = Music::Note->new($value, 'midinum');
                $result .= ', ' . $note->format('midi');
            }
            $result .= "\n";
        }
    }
    $result;
}


#####  Implementation (non-public)

has _client_number => (
    is       => 'ro',
    isa      => 'HashRef[Int]',
    writer   => '_set_client_number',
    init_arg => undef,  # not to be supplied in 'new'
);

sub BUILD {
    my ($self) = @_;
    # Register this running program as an ALSA MIDI client.
    if (not MIDI::ALSA::client($self->application_name, 1, 1, 0)) {
        croak "MIDI::ALSA::client failed";
    }
    my %client_number = map {
        lc $_
    } reverse MIDI::ALSA::listclients();
    $self->_set_client_number(\%client_number);
    my $config_lines = _config_lines(\@ARGV);
    my $fspec = $self->_set_filter_spec(FilterSpecification->new());
    $fspec->process($config_lines);
    my ($sources, $dests) = $self->_alsa_ports($config_lines);
    $self->_set_source_ports($sources);
    $self->_set_destination_ports($dests);
    $self->_set_midi_stream(MIDI_EventStream->new(
            source_ports => $self->source_ports,
            destination_ports => $self->destination_ports,
            config => $self));
}

sub debug {
    my ($self) = @_;
}

# Uncommented lines, lower-cased, from the configuration file(s) (ArrayRef)
sub _config_lines {
    my ($files) = @_;
    use IO::File qw();
    my $result;

    for my $f (@$files) {
        if (-f $f) {
            if (-r $f) {
                my $file = IO::File->new($f, "r");
                if (defined $file) {
                    my $line;
                    while ($line = <$file>) {
                        chomp $line;
                        $line = lc $line;
                        $line =~ s@\s*#.*@@;    # Remove tail comments.
                        push @$result, $line;
                    }
                    undef $file;    # close $file
                }
            } else {
                carp "File $f is not readable.";
            }
        }
    }
    $result;
}

# ALSA source and destination ports (array with two members, each of which is
# an ArrayRef), extracted from the specified strings (ArrayRef - lines from
# configuration file)
sub _alsa_ports {
    my ($self, $lines) = @_;
    my @result = ([], []);
    Readonly::Scalar my $FROM => 0;
    Readonly::Scalar my $TO   => 1;

    my $client_number = $self->_client_number;
    for my $line (@$lines) {
        # (Example valid line: 'to: rosegarden, 0')
        if ($line =~ /^([a-z]+:?)\s*(\w+),\s*(\d+)\s*$/) {
            my ($tag, $name, $minor_number) = ($1, $2, $3);
            if (exists $client_number->{$name}) {
                my $major_number = $client_number->{$name};
                if ($tag =~ /from:?/) {
                    push @{$result[$FROM]}, [$major_number, $minor_number];
                } elsif ($tag =~ /to:?/) {
                    push @{$result[$TO]}, [$major_number, $minor_number];
                } else {
                    carp "Invalid port-spec line: $line";
                }
            } else {
            }
        }
    }
    @result;
}


1;
