
%tools

ls : txt -> txt {

    @BASH {
        ls  >> $1
        echo 'FINISHED' >> $1
    }

}

du : txt -> txt {

    @BASH {
        du -hs $1 > size.txt
    }

}


%tasks

ls(file.txt)
du(file.txt)

