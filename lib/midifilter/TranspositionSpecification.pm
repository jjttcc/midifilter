package TranspositionSpecification;
# Specifications for a MIDI pitch transposition

use Mouse;
use Modern::Perl;


# Lowest pitch (inclusive) to trigger the transposition
has bottom_pitch => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

# Highest pitch (inclusive) to trigger the transposition
has top_pitch => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

# Number of steps (i.e., half-steps) to transpose - positive or negative
has steps => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

1;

