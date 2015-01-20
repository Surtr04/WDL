
%tools
tmx2ptd : tmx -> ptd {
    @BASH {
        nat-create -id $B1.ptd -tmx $1
    }

}


tmx2tmxa : $l1.$l2.tmx -> tmxa {
    @BASH {
        tmx2tmxa -l $l1-$l2 -f $1 > $B1.$l1.$l2.tmxa
    }
}


tmxa2ptda : tmxa -> ptda {
    @BASH {
        tmxa-lemmatizer -i $1 > $B1.tmxpl
        nat-create -id=$B1.ptda -tmx $B1.tmxpl
    }
}

someTask : type1 -> type2 {

	@PERL {
	    while () \{
            print $1;
        \}	
		print ($1);
	}
}


%tasks

tmx2tmxa (friedrich_nietzsche.pt.en.tmx)
tmxa2ptda (friedrich_nietzsche.pt.en.tmxa)
