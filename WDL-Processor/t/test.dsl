%mach

rmb@per-fide.di.uminho.pt { machType = ssh }
cpd22781@search.di.uminho.pt { machType = cluster }
user@natura.di.uminho.pt { machType = ssh }

%tools
tmx2ptd : tmx -> ptd {
    @BASH {
        nat-create -id $B1.ptd -tmx $1
    }
    split = @BASH {
        tmx
    }

    join = @BASH {
        cat
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

//this a comment
%tasks
tmx2tmxa (corpus.pt-en.tmx)
tmx2tmxa (corpus.en-pt.tmx)
tmxa2ptda (corpus.tmxa)

//and another one
