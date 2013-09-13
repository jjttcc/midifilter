package BankSelect_MIDI_Event;
# MIDI events to be output as two bank-select (MSB and LSB) events

use Mouse;
use Modern::Perl;

extends 'MIDI_Event';


#####  Public interface

has current_bank => (
    is      => 'ro',
    isa     => 'ArrayRef[Int]',
    default => sub { [0, 0] },
    writer  => '_set_current_bank',
);


#####  Interface implementation (public)


sub dispatch {
    my ($self) = @_;
say ref $self, "::dispatch called - self:", Dumper($self);
say "dests: ", Dumper($self->destinations);
# !!!!dummy - needs implementation
    $self->_send_output();
}

1;
