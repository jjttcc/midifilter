package AppConfiguration;
# midifilter application configuration facilities

use Mouse;
use Modern::Perl;
use constant::boolean;
use File::Basename qw(basename);
use Readonly;
use Carp;
use Data::Dumper;

extends 'MIDI_Configuration';

#####  Public interface

# MIDI event stream
has midi_stream => (
    is      => 'ro',
    isa     => 'MIDI_EventStream',
    writer  => '_set_midi_stream',
);

# Name of the running program
has program_name => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { basename($0); }
);

# Print debugging/tracing information?
has verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { FALSE; }
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


#####  Implementation

sub BUILD {
    my ($self) = @_;
    my ($sources, $dests) = _alsa_ports(\@ARGV);
say '$sources, $dests: ', Dumper($sources, $dests);
say "my name is ", $self->program_name;
    $self->_set_source_ports($sources);
    $self->_set_destination_ports($dests);
    $self->_set_midi_stream(MIDI_EventStream->new(
            source_ports => $self->source_ports,
            destination_ports => $self->destination_ports,
            config => $self));
    # Register this running program as an ALSA MIDI client.
    if (not MIDI::ALSA::client($self->program_name, 1, 1, 0)) {
        croak "MIDI::ALSA::client failed";
    }
}

sub debug {
    my ($self) = @_;
say "DEBUG: sources: " . Dumper($self->source_ports());
say "DEBUG: destinations: " . Dumper($self->destination_ports());
}

# ALSA source and destination ports (array with two members, each of which is
# an ArrayRef), extracted from the specified files
sub _alsa_ports {
    my ($files) = @_;
    my @result = ([], []);
    use IO::File qw();
say "_alsa_ports - files: ", Dumper($files);
    Readonly::Scalar my $FROM => 0;
    Readonly::Scalar my $TO   => 1;

    for my $f (@$files) {
        if (-f $f) {
            if (-r $f) {
                my $file = IO::File->new($f, "r");
                if (defined $file) {
                    my $line;
                    while ($line = <$file>) {
                        $line = lc $line;
                        # (Example valid line: '16, 0')
                        if ($line =~ /^([a-z]+:?)\s*(\d+)[,:]\s*(\d+)\s*$/) {
                            my ($tag, $part1, $part2) = ($1, $2, $3);
                            if ($tag =~ /from:?/) {
                                push @{$result[$FROM]}, [$part1, $part2];
                            } elsif ($tag =~ /to:?/) {
                                push @{$result[$TO]}, [$part1, $part2];
                            } else {
                                carp "Invalid port-spec line: $line";
                            }
                        }
                    }
                    undef $file;    # close $file
                }
            } else {
                carp "File $f is not readable.";
            }
        }
    }
    @result;
}

1;
