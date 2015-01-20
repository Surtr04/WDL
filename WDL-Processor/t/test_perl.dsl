%mach

rmb@per-fide.di.uminho.pt { machType = ssh tag = per-fide}
cpd22781@search.di.uminho.pt {machType = cluster}
user@natura.di.uminho.pt {machType = ssh}

%tools

tmx2ptd : tmx -> ptd {
    @BASH {
        nat-create -id $B1.ptd -tmx $1
    }

}


tmx2tmxa : $l1-$l2.tmx -> tmxa {
    @BASH {
        tmx2tmxa -l $l1-$l2 -f $1 -o $B1.$l1.$l2.tmxa
    }
}


tmxa2ptda : tmxa -> ptda {
    @BASH {
        tmxa-lemmatizer -i $1 -o $B1.tmxpl
        nat-create -id $B1.ptda -tmx $B1.tmxpl
    }
}

test : $a1-$a2-$a3.type1 -> type2 {

    @BASH {
        someCode -i $a1 -a $a2 -o $a3
    }

}

perlCodeTest : ~txt -> txt2 {

    @PERLBEGIN
        open FILE ,"<", "\1"; 
        while (<FILE>) {
            print $_;
        }
    @PERLEND
}


%tasks

perlCodeTest(simple.wdl) @per-fide
