filterByWhoisParam()
{
    #input params
    whoisParam="$1"
    valueParam="$2"
    file="$3"

    IFS=$'\n';
    for value in $(cat ~/results/starbucks.amass.txt );
        do  #echo -n "$value "; 
            whoisResult=$(whois "$value"|grep "Tech Organization"|grep Starbucks)
            if [ ${#whoisResult} -gt 0 ]
            then
                echo "$value"   
            fi
            sleep 1 
    done
}

# This function extracts a domain from the program inscope 
# and calls amass to find other first level domains related to it. 
# you need to verify that the new domains belong to the target 
# try using filterByWhoisParam
getMoreInscope()
{
    program="$1";
    domain=$(bbrf scope in --wildcard -p "$program"|grep -v DEBUG|head -n 1)
    amass intel -config ~/amass_config.ini -d $domain -whois #|awk '{print  "*."$1}
}

