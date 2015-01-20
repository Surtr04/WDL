package WDL::Processor::Sched;

use base qw (WDL::Processor);

use strict;
use warnings;
use Data::Dumper;
use WDL::Processor;
use Proc::Simple;
use WDL::TimeStamp;
use WDL::Processor::Logger;

our @perl_files;



sub new {

    my $class = shift;

    my $self = {
        running => {},
    };

    bless $self,$class;

    return $self;

}

sub launchLocal {

   Proc::Simple::debug(1);
   my ($self, $data, $toRun) = @_;
   my $proc = Proc::Simple->new();
   my $res;
   my $tool;
   my $non_critical;
   my $runData = $_;

   $res = $data->{run}->{$runData}->{resource};
   $tool = $data->{run}->{$runData}->{tool};
   $non_critical = $data->{run}->{$runData}->{non_critical};

   readyPerl($data,$runData) if ($data->{run}->{$runData}->{perl});
   if (checkResource($res,$non_critical) && canRun($self,$res)) {
       my $r = $toRun->{code};
       
       if ($toRun->{perl}) {
           $r = "perl $res$tool.pl";
       }

       $proc->start( $r );
       WDL::TimeStamp::updateTimestamp( $toRun->{destResource} );
       print "Launching $res with pid:" . $proc->pid ."\n";

       $self->{running}->{ $toRun->{destResource} } = $proc;
       delete $data->{run}->{$runData};
   }

   return $proc;

}

sub readyPerl {

    my ($data,$runData) = @_;
    my $res = $data->{run}->{$runData}->{resource};
    my $tool = $data->{run}->{$runData}->{tool};

    open PERLCODE,">","$res$tool.pl";
    print PERLCODE $data->{run}->{$runData}->{code};
    close PERLCODE;

    push @perl_files, "$res$tool.pl";

}

sub checkResource {

    my ($res,$non_critical) = @_;
    return 1 if defined $non_critical;
    return 1 if (-e $res);

    return 0;

}


sub canRun {

    my $self = shift;
    my $resource = shift;
    my $proc = $self->{running}->{$resource};
    print Dumper $proc;

    return 1 if not defined $proc;

    if ($proc->poll()) {

        WDL::Processor::Logger::launch($resource);

        return 0;
    }

    1;
}


sub launchSSH {

    my ($self,$data,$toRun) = @_;

    print Dumper $data;

}

sub launchCluster {

}

1;
