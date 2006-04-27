use strict;
use Test::More tests => 29;
use Test::Deep;
use t::common qw( new_fh );

use_ok( 'DBM::Deep' );

my ($fh, $filename) = new_fh();
my $db1 = DBM::Deep->new(
    file => $filename,
    locking => 1,
    autoflush => 1,
    type => DBM::Deep->TYPE_ARRAY,
);

my $db2 = DBM::Deep->new(
    file => $filename,
    locking => 1,
    autoflush => 1,
    type => DBM::Deep->TYPE_ARRAY,
);

$db1->[0] = 'y';
is( $db1->[0], 'y', "Before transaction, DB1's 0 is Y" );
is( $db2->[0], 'y', "Before transaction, DB2's 0 is Y" );

$db1->begin_work;

    is( $db1->[0], 'y', "DB1 transaction started, no actions - DB1's 0 is Y" );
    is( $db2->[0], 'y', "DB1 transaction started, no actions - DB2's 0 is Y" );

    $db1->[0] = 'z';
    is( $db1->[0], 'z', "Within DB1 transaction, DB1's 0 is Z" );
    is( $db2->[0], 'y', "Within DB1 transaction, DB2's 0 is still Y" );

    $db2->[1] = 'foo';
    is( $db2->[1], 'foo', "DB2 set 1 within DB1's transaction, so DB2 can see it" );
    ok( !exists $db1->[1], "Since 1 was added after the transaction began, DB1 doesn't see it." );

    cmp_ok( scalar(@$db1), '==', 1, "DB1 has 1 element" );
    cmp_ok( scalar(@$db2), '==', 2, "DB2 has 2 elements" );

$db1->rollback;

is( $db1->[0], 'y', "After rollback, DB1's 0 is Y" );
is( $db2->[0], 'y', "After rollback, DB2's 0 is Y" );

is( $db1->[1], 'foo', "After DB1 transaction is over, DB1 can see 1" );
is( $db2->[1], 'foo', "After DB1 transaction is over, DB2 can still see 1" );

cmp_ok( scalar(@$db1), '==', 2, "DB1 now has 2 elements" );
cmp_ok( scalar(@$db2), '==', 2, "DB2 still has 2 elements" );

$db1->begin_work;

    is( $db1->[0], 'y', "DB1 transaction started, no actions - DB1's 0 is Y" );
    is( $db2->[0], 'y', "DB1 transaction started, no actions - DB2's 0 is Y" );

    $db1->[2] = 'z';
    is( $db1->[2], 'z', "Within DB1 transaction, DB1's 2 is Z" );
    ok( !exists $db2->[2], "Within DB1 transaction, DB2 cannot see 2" );

    cmp_ok( scalar(@$db1), '==', 3, "DB1 has 3 elements" );
    cmp_ok( scalar(@$db2), '==', 2, "DB2 has 2 elements" );

$db1->commit;

is( $db1->[0], 'y', "After rollback, DB1's 0 is Y" );
is( $db2->[0], 'y', "After rollback, DB2's 0 is Y" );

is( $db1->[2], 'z', "After DB1 transaction is over, DB1 can still see 2" );
is( $db2->[2], 'z', "After DB1 transaction is over, DB2 can now see 2" );

cmp_ok( scalar(@$db1), '==', 3, "DB1 now has 2 elements" );
cmp_ok( scalar(@$db2), '==', 3, "DB2 still has 2 elements" );
