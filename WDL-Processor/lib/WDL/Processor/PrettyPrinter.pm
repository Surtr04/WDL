package WDL::Processor::PrettyPrinter;

use base qw(WDL::Processor);

use strict;
use warnings;
use Data::Dumper;
use GraphViz;
use WDL::Processor;


sub generateGraphGViz {

    my $self = shift;

    my $dot = GraphViz->new(rankdir => "LR");
    open FILE, ">", "graph.dot" or die $!;

    for (sort {$a <=> $b} keys %{$self->{run}}) {

        my $resource = $self->{run}->{$_}->{resource};
        my $tool = $self->{run}->{$_}->{tool};

        $dot->add_node($resource);

        my $newResource = WDL::Processor::newResourceType($resource,$self->{tools}->{$tool}->{dtype});
        $dot->add_node($newResource);
        $dot->add_edge($resource => $newResource, label => $tool);

    }
    print FILE $dot->as_dot;
    close FILE;
    qx /dot -Tpdf graph.dot > graph.pdf/;
    unlink "graph.dot";
}

sub generateTypeGraphViz {

    my $self = shift;

    my $dot = GraphViz->new();
    open FILE, ">", "typeGraph.dot" or die $!;

    for (keys %{$self->{tools}}) {

        my $stype = $self->{tools}->{$_}->{stype};
        my $dtype = $self->{tools}->{$_}->{dtype};
        $stype =~ s/.*\.(.*)/$1/g;
        $dtype =~ s/.*\.(.*)/$1/g;

        $dot->add_node($stype);
        $dot->add_node($dtype);
        $dot->add_edge($stype => $dtype, label => $_);
    }

        print FILE $dot->as_dot;
        close FILE;
        qx/dot -Tpdf typeGraph.dot > typeGraph.pdf/;
        unlink "typeGraph.dot";

}

1;
