getDisabledPrograms()
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
diffFiles(){
    comm -3 <(sort $1) <(sort $2) > $3
}

getDomains()
{
    bbrf scope in --wildcard|bbrf inscope add -; 
    bbrf scope in --wildcard|bbrf domain add - --show-new; 
    bbrf scope in |bbrf domain add - --show-new; 
    bbrf scope in| subfinder -t 60 -silent |bbrf domain add - -s subfinder  --show-new; 
    bbrf scope in|assetfinder|bbrf domain add - -s assetfinder
}

getUrls()
{
    RED="\e[31m"
    YELLOW="\e[33m"
    ENDCOLOR="\e[0m"

    IFS=$'\n'
    domains=$(bbrf domains|grep -v DEBUG) 
    if [ ${#domains} -gt 0 ] 
        then
            echo -en "${RED} httpx domains"        
            echo $domains |httpx -silent -threads 100 |bbrf url add - -s httpx --show-new
            echo -en "${RED} httprobe domains"        
            echo $domains |httprobe -c 50 |bbrf url add - -s httprobe --show-new
    fi
}
