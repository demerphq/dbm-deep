package DBM::Deep::Engine::Sector::Null;

use 5.006_000;

use strict;
use warnings FATAL => 'all';

use DBM::Deep::Engine::Sector::Data;
our @ISA = qw( DBM::Deep::Engine::Sector::Data );

sub type { $_[0]{engine}->SIG_NULL }
sub data_length { 0 }
sub data { return }

sub _init {
    my $self = shift;

    my $engine = $self->engine;

    unless ( $self->offset ) {
        $self->{offset} = $engine->_request_data_sector( $self->size );

        my $string = chr(0) x $self->size;

        substr( $string, 0, 1, $self->type );
        substr( $string, $self->base_size, $engine->byte_size + 1,
            pack( $engine->StP($engine->byte_size), 0 )   # Chain loc
          . pack( $engine->StP(1), $self->data_length ),  # Data length
        );

        $engine->storage->print_at( $self->offset, $string );

        return;
    }
}

1;
__END__