package WDL::Processor;

use 5.0200;
use strict;
use warnings;
use Data::Dumper;
use Graph;
use Graph::Directed;
use Set::Scalar;
use experimental 'smartmatch';
require Exporter;
use Carp::Always;
use WDL::TimeStamp;
use WDL::Processor::Logger;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.7';
our $done;
our @wdl_tools;


sub new {

    my $class = shift;

    my $self = {
        tools => {},
        tasks => {},
        run => {},
        toolSet => Set::Scalar->new,
    };


    bless $self,$class;

    return $self;
}


sub createTool {

    my $self = shift;
    my $toolName = shift;
    my %meta = @_;

    $self->{tools}->{$toolName} = {};
    $self->{tools}->{$toolName}->{stype} = $meta{st};
    $self->{tools}->{$toolName}->{dtype} = $meta{dt};
    $self->{tools}->{$toolName}->{non_critical} = $meta{non_critical};
    $self->{tools}->{$toolName}->{split} = $meta{split};
    $self->{tools}->{$toolName}->{join} = $meta{join};

    my $src_bash = $meta{code}{bash} ;
    my $src_perl = $meta{code}{perl} ;
    my @tools;
    @tools = split /\n/ ,$src_bash if defined $src_bash;
    @tools = $src_perl if defined $src_perl;
    foreach (@tools) {
        $_ =~ s/^\s+(.*)[\s\n]*$/$1/;
    }
    @tools = grep {$_ ne ''} @tools;

    foreach (@tools) {
        $_ =~ m/^([\w\d\-\_]+)\s.*/;
        $self->{toolSet}->insert($1);
    }


    @{$self->{tools}->{$toolName}->{bash}} = @tools if defined $src_bash;
    @{$self->{tools}->{$toolName}->{perl}} = @tools if defined $src_perl;
    @wdl_tools = @tools;
}



sub createTask {

    my $self = shift;
    my @tasks = @_;


    $self->{tasks} = pop @tasks;

}


sub createMach {

    my $self = shift;
    my %meta = @_;
 

    $self->{machs}->{$meta{host}}->{type} = $meta{type};
    $self->{machs}->{$meta{host}}->{user} = $meta{user};
    $self->{machs}->{$meta{host}}->{parameters} = $meta{parameters};
}


sub prepareRun {

    my $self = shift;
    my $toolNum = 1;


    foreach (@{$self->{tasks}}) {
        my $tool = $_->{tool};
        my $runAt = $_->{runAt};
    
        my $_1 = $_->{args}[0];
        $_->{resource} = $_1;       
        $_1 =~ m/^(.*)\..*$/;
        my $B1 = $1;
        my $ctype;

        generateTypeGraph($self);
        generateGraph($self);

        if ($B1 =~ m/\./g)  {     # compound type
            $B1 =~ m/^([^\.]*)\.(.*)/;
            $B1 = $1;
            $ctype = $2;
        }

        if($_->{span}) {
            my $t = prepareSpan($self,$_1,$B1,$toolNum,$self->{typeGraph},$ctype);
            $toolNum += ($t - 1) ;
            next;
        }

        if($_->{make}) {
            my $t = prepareMake($self,$_1,$B1,$toolNum,$self->{typeGraph},$ctype);
            $toolNum += ($t - 1);
            next;
        }

        prepareSkel($self,$tool,$B1,$_1,$toolNum,$ctype,$runAt) ;
        $toolNum+=1;
    }

}

sub prepareSpan {

    my ($self,$_1,$B1,$toolNum,$tgraph,$ctype) = @_;
    $_1 =~ m/.*\.(.*)$/;
    my $type = $1;
    my @r = $tgraph->all_reachable($type);
    foreach my $v (@r) {
        for (keys %{$self->{tools}}) {
            if ($self->{tools}{$_}{dtype} eq $v) {
                prepareSkel ($self,$_,$B1,$_1,$toolNum,$ctype);
            }
        }
        $toolNum += 1;
    }

    return $toolNum;

}


sub prepareMake {

    my ($self,$_1,$B1,$toolNum,$tgraph,$ctype) = @_;
    $_1 =~ m/.*\.(.*)$/;
    my $type = $1;
    my $sourceFound = 0;
    my $inserted = 0;
    my $iter = 0;

    my @r = $tgraph->all_predecessors($type);
    push @r , $type;
    my @types = @r;

    while (@r) {
        die "Couldn't find matching source file in Make rule for $_1 target\n" if ($iter == ((scalar @types) + 1)); #die after 1 traversal
        $iter += 1;

        my $v = shift @r;
        my $nResource = newResourceType($_1,$v);

        if( -e $nResource || $sourceFound) {

            $sourceFound = 1;
            $_1 = $nResource;
            my @tools = findToolBySType($self,$v);

            foreach my $tool (@tools) {
                if ($self->{tools}{$tool}{dtype} ~~ @types ) {
                    $inserted += 1;
                    prepareSkel($self,$tool,$B1,$_1,$toolNum,$ctype);
                }
            }

        }

        if (!$sourceFound) {
            push @r,$v;
        }
        elsif ($inserted) {
            $inserted = 0;
            $toolNum += 1;
        }

    }

    return $toolNum;
}

sub findToolBySType {

    my ($self,$type) = @_;
    my $tool;
    my @tools;
    my $st;

    for (keys %{$self->{tools}}) {

        $st = $self->{tools}{$_}{stype};

        if ($st =~ m/.*\.(.*)$/ ) {
            $st = $1;
        }

        if ($st eq $type) {
            push @tools, $_;
        }
    }

    return @tools;
}

sub findToolByDType {

    my ($self,$type) = @_;
    my $tool;
    my @tools;
    my $st;

    for (keys %{$self->{tools}}) {

        $st = $self->{tools}{$_}{stype};

        if ($st =~ m/.*\.(.*)$/ ) {
            $st = $1;
        }

        if ($st eq $type) {
            push @tools, $_;
        }
    }

    return @tools;
}

sub findToolBySDType {

    my ($self,$stype,$dtype) = @_;

    for (keys %{$self->{tools}}) {
        if ($self->{tools}{$_}{stype} eq $stype and $self->{tools}{$_}{dtype} eq $dtype) {
            return $_;
        }
    }
}

sub prepareSkel {

        my ($self,$tool,$B1,$_1,$toolNum,$ctype,$runAt) = @_;
        my $codeType;
        my $skel = $self->{tools}->{$tool};
        my $non_critical = $self->{tools}->{$tool}->{non_critical};
        if ($skel->{bash}) {

            $codeType = 'bash';
            prepareSkelBash($self,$skel->{bash},$tool,$B1,$_1,$ctype,$toolNum,$non_critical,$runAt);

        }
        elsif ($skel->{perl}) {

            $codeType = 'perl';
            prepareSkelPerl($self,$skel->{perl},$tool,$B1,$_1,$ctype,$toolNum,$non_critical,$runAt);
        }

        
}


sub prepareSkelBash {

    my ($self,$skel,$tool,$B1,$_1,$ctype,$toolNum,$non_critical,$runAt) = @_;
    
    foreach ($skel) {
            my $exec = join ("\n",@$_);
            my $tskel = $self->{tools}->{$tool}->{stype};
            $exec =~ s/\$B1/$B1/g;
            $exec =~ s/\$1/$_1/g;
            if (defined $ctype) {
                my $sep = findSeparator($ctype);
                my @vars;
                my @svars;
                @vars = split /\Q$sep\E/, $ctype;
                @svars = split /[\Q$sep\E\.]/, $tskel;
                @svars = grep {/^\$/} @svars;
                foreach (@svars) {
                    my $tmp = shift @vars;
                    $exec =~ s/\Q$_\E/$tmp/g;
                }
            }
            my $type = $self->{tools}->{$tool}->{stype};
            $type =~ s/.*\.(.+)$/$1/;
            $_1 =~ s/(.*)\..*$/$1.$type/;
            my $newType = newResourceType($_1,$self->{tools}->{$tool}->{dtype});

#            print "$_1 -> $newType\n";
            if ( WDL::TimeStamp::checkUpdate($_1,$newType) ) {
                $self->{run}->{$toolNum}->{tool} = $tool;
                $self->{run}->{$toolNum}->{resource} = $_1;
                $self->{run}->{$toolNum}->{destResource} = $newType;
                $self->{run}->{$toolNum}->{non_critical} = $non_critical;
                $self->{run}->{$toolNum}->{runAt} = $runAt;
                $self->{run}->{$toolNum}->{code} = join ((';',split /\n/, $exec));
            }
            else {
                WDL::Processor::Logger::recalculate($newType);
            }

        }


}

sub prepareSkelPerl {
 
    my ($self,$skel,$tool,$B1,$_1,$ctype,$toolNum,$non_critical,$runAt) = @_;
    
    
    foreach ($skel) {
            my $exec = join ("\n",@$_);
            my $tskel = $self->{tools}->{$tool}->{stype};
            $exec =~ s/\$B1/$B1/g;
            $exec =~ s/\\1/$_1/g;
            if (defined $ctype) {
                my $sep = findSeparator($ctype);
                my @vars;
                my @svars;
                @vars = split /\Q$sep\E/, $ctype;
                @svars = split /[\Q$sep\E\.]/, $tskel;
                @svars = grep {/^\$/} @svars;
                foreach (@svars) {
                    my $tmp = shift @vars;
                    $exec =~ s/\Q$_\E/$tmp/g;
                }
            }
            my $type = $self->{tools}->{$tool}->{stype};
            $type =~ s/.*\.(.+)$/$1/;
            $_1 =~ s/(.*)\..*$/$1.$type/;
            my $newType = newResourceType($_1,$self->{tools}->{$tool}->{dtype});

#            print "$_1 -> $newType\n";
            if ( WDL::TimeStamp::checkUpdate($_1,$newType) ) {
                $self->{run}->{$toolNum}->{perl} = 1;
                $self->{run}->{$toolNum}->{tool} = $tool;
                $self->{run}->{$toolNum}->{resource} = $_1;
                $self->{run}->{$toolNum}->{destResource} = $newType;
                $self->{run}->{$toolNum}->{non_critical} = $non_critical;
                $self->{run}->{$toolNum}->{runAt} = $runAt;
                $self->{run}->{$toolNum}->{code} = join ((';',split /\n/, $exec));
            }
            else {
                WDL::Processor::Logger::recalculate($newType);
            }

        }

}



sub findSeparator {

    my ($str) = @_;
    if ($str =~ m/\-/g) {
        return "-";
    }
    if ($str =~ m/\./g) {
        return ".";
    }
    if ($str =~ m/\,/g) {
        return ",";
    }
    if ($str =~ m/_/g) {
        return "_";
    }
}

sub generateGraph {

    my $self = shift;
    my $graph = Graph::Directed->new();
    my $newResource;
    for my $k (sort keys %{$self->{run}}) {

        my $resource = $self->{run}->{$k}->{resource};
        my $tool = $self->{run}->{$k}->{tool};

        $graph->add_vertex($resource);
        $newResource = newResourceType($resource,$self->{tools}->{$tool}->{dtype});
        $graph->add_vertex($newResource);
        $graph->add_weighted_edge($resource,$newResource,$tool);

    }
    $self->{depGraph} = $graph;
}






sub generateTypeGraph {

    my $self = shift;
    my $graph = Graph::Directed->new;

    for (keys %{$self->{tools}}) {

        my $stype = $self->{tools}->{$_}->{stype};
        my $dtype = $self->{tools}->{$_}->{dtype};
        $stype =~ s/.*\.(.*)/$1/g;
        $dtype =~ s/.*\.(.*)/$1/g;

        $graph->add_vertex($stype);
        $graph->add_vertex($dtype);
        $graph->add_weighted_edge($stype,$dtype,$_);
        }

    $self->{typeGraph} = $graph;

}



sub newResourceType {

    my ($resource, $newType) = @_;
    $resource =~ s/(.*)\.[\w\d]+$/$1.$newType/;
    return $resource;

}



1;
__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

WDL::Processor - Perl extension for blah blah blah

=head1 SYNOPSIS

  use WDL::Processor;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for WDL::Processor, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Rui Brito, E<lt>ruibrito@666@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Rui Brito

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.19.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
