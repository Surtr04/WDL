package WDL::TimeStamp;


use strict;
use warnings;
use Data::Dumper;
require Exporter;
use utf8::all;
use Time::HiRes qw (gettimeofday);

#our @ISA = qw(Exporter);
#our %EXPORT_TAGS = ( 'all' => [ qw() ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{ 'all' } } );
#our @EXPORT = qw();


sub readAsHash {

    $/ = "\n";
    my $hash = {};
    if (-e ".timestamp") {
        open TIMESTAMP, "<", ".timestamp";
    }
    else {
        open TIMESTAMP, "+>", ".timestamp";
    }


    while (<TIMESTAMP>) {
       my ($key,$value) = split /:/, $_;
       $hash->{$key} = $value;
    }

    close TIMESTAMP;
    return $hash;
}


sub checkUpdate {

    my ($res1,$res2) = @_;

    if ($res1 eq $res2) {
        return 0;
    }

    my $file = readAsHash;

    my $t1 = $file->{$res1};
    my $t2 = $file->{$res2};

    if (not defined $t2) {
        return 1;
    }
    elsif (not defined $t1) { #root file
        return 0;
    }

    if ($t1 < $t2) {
        return 0;
    }

    if ($t1 > $t2) {
        delete $file->{$res2};
        rewriteTimestamps($file);
        return 1;
    }

    return 1;
}


sub updateTimestamp {

    my $file = shift;

    my $timestamps = readAsHash;

    if ( $timestamps->{$file} ) {
        return 0;
    }
    else {
        $timestamps->{$file} = gettimeofday;
        rewriteTimestamps($timestamps);
    }

    return 1;
}


sub rewriteTimestamps {
    my $file = shift;

    open TIMESTAMP, ">",".timestamp";
    for (keys %{$file}) {
        print TIMESTAMP "$_:$file->{$_}\n";
    }
    close TIMESTAMP;

}


1;
