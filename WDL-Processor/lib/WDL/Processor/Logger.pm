package WDL::Processor::Logger;

use base qw (WDL::Processor);

use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl;
use Term::ANSIColor;

sub new {

    my $class = shift;

    my $self = {
    };

    bless $self,$class;

    return $self;

}


sub genLog {

    my $self = shift;


    open LOG, ">", "log";

    for (keys %{$self->{running}}) {
        my $proc = $self->{running}->{$_};
        print LOG $_ ."\n";
        my $time = $proc->t1() ;
        print LOG "Execution Time: $time";
        print LOG "\n\n";
    }

}


sub recalculate ($) {
    
    my $t = shift;

    print color 'green';
    print "No need to recalculate $t\n";
    print color 'reset';


}

sub launch ($) {

    my $res = shift;

    print color 'bold red';
    print "Can't launch $res\n";
    print color 'reset';

}

sub toolAvailable ($) {

    my $tool = shift;

    print color 'green';
    print "$tool : available\n";
    print color 'reset';
}

sub toolUnavailable ($) {

    my $tool = shift;

    print color 'bold red';
    print "$tool : unavailable\n";
    print color 'reset';

}

1;
