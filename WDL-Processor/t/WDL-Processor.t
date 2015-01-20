# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl WDL-Processor.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('WDL') };
BEGIN { use_ok('WDL::Processor') };
BEGIN { use_ok('WDL::Processor::Sched') };
BEGIN { use_ok('WDL::Processor::PrettyPrinter' ) };
BEGIN { use_ok('WDL::TimeStamp') };
BEGIN { use_ok('WDL::Processor::Logger') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

