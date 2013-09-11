package MIDI_EventFilter;
# MIDI event filtering logic

use Mouse;
use Modern::Perl;
use constant::boolean;
use MIDI_Event;
use Readonly;
use Normal_MIDI_Event;
use Overriding_MIDI_Event;
use ProgramChange_MIDI_Event;

# !!!!!!!!!!Clean this up, please!!!!!!!!!!!!!:
#NOTEON     => $MIDI_Facilities::SND_SEQ_EVENT_NOTEON,
#NOTEOFF    => $MIDI_Facilities::SND_SEQ_EVENT_NOTEOFF,
#CONTROLLER => $MIDI_Facilities::SND_SEQ_EVENT_CONTROLLER,
#sub NOTEON() { $MIDI_Facilities::SND_SEQ_EVENT_NOTEON }
#sub NOTEOFF() { $MIDI_Facilities::SND_SEQ_EVENT_NOTEOFF }
#sub CONTROLLER() { $MIDI_Facilities::SND_SEQ_EVENT_CONTROLLER }


with 'MIDI_Facilities';

#####  Public interface

###  Constants

# Event-filtering processing states
Readonly::Scalar our $NORMAL         => 0;  # Next event to be output as is
Readonly::Scalar our $OVERRIDE       => 1;  # Command override state
Readonly::Scalar our $PROGRAM_CHANGE => 2;  # Program change to be sent

###  Access

has current_event => (
    is       => 'ro',
    isa      => 'Maybe[MIDI_Event]',
# !!!!rm: default  => sub { MIDI_Event->new(); }, # initialize with dummy object
    init_arg => undef,   # Not allowed in 'new' method.
    writer   => '_set_current_event',
);

# Current MIDI-event processing state
has state => (
    is       => 'ro',
    isa      => 'Int',
    default  => sub { $NORMAL; },
    init_arg => undef,   # Not allowed in 'new' method.
# !!!    writer   => '_set_state',
);

my $event_count = 0;

# Input the next, pending, event and according its type and the current state,
# dispatch (i.e., output, change state, or etc.) the event appropriately.
sub dispatch_next_event {
    my ($self) = @_;
# !!!!
    my $current_bank = [0, 0];
    my $cmd_override = FALSE;
    my $program_change = FALSE;
    my $pc_top_range = FALSE;
    my $myself;

    my @alsa_event = input();
    ++$event_count;
    my $type = $alsa_event[TYPE()];
say "non: ", NOTEON();
say "nooff: ", NOTEOFF();
say "cntrl ", CONTROLLER();
    if ($type == NOTEON() or $type == NOTEOFF()) {
#        my $data = $alsa_event[DATA()];
#        my ($channel, $pitch, $velocity, undef, undef) = @$data;
        my $event = $self->_midi_event_map->{$self->state()};
        $event->dispatch();
say "AAAAAAAAAA";
# $self->_midi_event_map->{$self->state()}->dispatch(\@alsa_event);
    } elsif ($type == CONTROLLER()) {
        #xxx
say "BBBBBBBBBB";
    } else {
        #yyy
say "CCCCCCCCCC";
    }
#    SND_SEQ_EVENT_PGMCHANGE
#    SND_SEQ_EVENT_CONTROLLER
}

# !!!!Likely to be obsoleted/removed
# Obtain the next MIDI event
sub retrieve_next_event {
    my ($self) = @_;
    $self->_set_current_event(MIDI_Event->new());
}


# !!!!Likely to be obsoleted/removed
# Dispatch the current event according to its type, value, etc.
sub dispatch_current_event {
    my ($self) = @_;
# !!!!
    my $current_bank = [0, 0];
    my $cmd_override = FALSE;
    my $program_change = FALSE;
    my $pc_top_range = FALSE;
    my $myself;

# !!!!more to go!!!!
}


#####  Implementation

sub BUILD {
    my ($self) = @_;
say "MIDI_EventFilter::BUILD called";
    my $midimap = $self->_midi_event_map;
    $midimap->{$NORMAL} = Normal_MIDI_Event->new();
    $midimap->{$OVERRIDE} = Overriding_MIDI_Event->new();
    $midimap->{$PROGRAM_CHANGE} = ProgramChange_MIDI_Event->new();
}

# map of MIDI_Event subtype instances: processing-state -> appropriate subtype
has _midi_event_map => (
    is      => 'ro',
    isa     => 'HashRef[MIDI_Event]',
    default => sub { {} },  # Initialized to empty hash reference.
);

=cut=
    while (1) {
        my @alsaevent = input();
        ++$evcount;
        my ($type, $flags, $tag, $queue, $time, $source, $destination,
            $data) = @alsaevent;
        if (not defined $myself) {
            $myself = $destination;
        }
        my $repl_data = $data;
        switch ($type) {
            case [SND_SEQ_EVENT_NOTEON(), SND_SEQ_EVENT_NOTEOFF()] {
                my ($channel, $pitch, $velocity, undef, $duration) = @$data;
say "got note " . ($velocity == 0? 'OFF ': 'ON ') .
"event [$evcount]: " . Dumper(\@alsaevent) if $self->config->verbose;
                my $note = Music::Note->new($pitch, 'midinum');
say "note: " . $note->format('ISO') if $self->config->verbose;
say "source, dest: " . Dumper($source) . ", " .
Dumper($destination) if $self->config->verbose;
                if ($cmd_override and $pitch >= $MIDI_Facilities::CTL_START) {
                    if ($velocity == 0) {   # NOTE-OFF
                        $cmd_override = FALSE;
                        if ($pitch == $MIDI_Facilities::C8 or
                                $pitch == $MIDI_Facilities::B7) {
                            $program_change = TRUE;
                            if ($pitch == $MIDI_Facilities::B7) {
                                $pc_top_range = TRUE;
                            }
                        } elsif ($pitch == $MIDI_Facilities::Bb7) {
                            $current_bank = $self->change_bank_select(TRUE, $current_bank,
                                \@alsaevent, $myself, $destinations);
                        } elsif ($pitch == $MIDI_Facilities::A7) {
                            $current_bank = $self->change_bank_select(FALSE, $current_bank,
                                \@alsaevent, $myself, $destinations);
                        }
                    } else {
                        # $velocity != 0: NOTE-ON
                        # no-op when $cmd_override - i.e., throw the event away.
                    }
                } elsif ($program_change) {
                    if ($velocity == 0) {   # NOTE-OFF
                        # (program change was signalled with the previous event.)
                        $program_change = FALSE;
                        my $program = $pitch; # i.e., note-on pitch -> new program#
                        if (not $pc_top_range) {
                            $program -= $MIDI_Facilities::LOWEST_88KEY_PITCH;  # e.g., 21 => 0
                        } else {
                            $program += (127 - $MIDI_Facilities::HIGHEST_88KEY_PITCH); # 108 => 127
                        }
                        $pc_top_range = FALSE;
                        $self->change_program($flags, $tag, $queue, $time, $myself,
                            $destinations, [$channel, 0, 0, 0, 0, $program]);
                    } else {
                        # $velocity != 0: NOTE-ON
                        # no-op when $program_change - i.e., throw the event away.
                    }
                } else {
                    # Pass on the received note event.
                    for my $dest (@$destinations) {
                        output($type, $flags, $tag, $queue, $time, $myself,
                            $dest, $repl_data);
                    }
                }
            }
            case SND_SEQ_EVENT_CONTROLLER() {
    say STDERR "got a control change event [$evcount]: " .
    Dumper(\@alsaevent) if $self->config->verbose;
                my ($channel, undef, undef, undef, $param, $value) = @$data;
                if ($param == $MIDI_Facilities::CHANNEL_VOLUME) {
                    # control-change/channel-volume is (for now, at least)
                    # hard-coded to signal a change to command-override status.
                    $cmd_override = TRUE;
                } else {
                    for my $dest (@$destinations) {
                        # Pass on the received control change message.
                        output($type, $flags, $tag, $queue, $time, $myself,
                            $dest, $repl_data);
                    }
                }
            }
            else {
    say STDERR "got some other event [$evcount]: " .
    Dumper(\@alsaevent) if $self->config->verbose;
                    for my $dest (@$destinations) {
                        # Pass on the received event/message.
                        output($type, $flags, $tag, $queue, $time, $myself,
                            $dest, $repl_data);
                    }
            }
        }
    }
=cut=


1;

