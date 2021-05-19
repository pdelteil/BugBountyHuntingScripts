getdisabledprograms()
{
    for value in $(bbrf programs --show-disabled 2>/dev/null);
        do 
            disabled=$(bbrf show "$value" 2>/dev/null| jq '.disabled')
            if [ "$disabled" == "true" ] 
            then
                echo -e $value
            fi
    done
}
diff_files(){
    comm -3 <(sort $1) <(sort $2) > $3
}
