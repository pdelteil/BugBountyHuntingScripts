filterByWhoisParam()
{
    if [[ -z "$1" ]]  | [[ -z "$2" ]]; then
        echo -en "\nUse ${FUNCNAME[0]} whoisParam [optional] valueParam outputfile\n\n"
        echo "Example  ${FUNCNAME[0]} \"Tech Organization\" \"Starbucks\" inputDomains.txt" 
        echo "Example  ${FUNCNAME[0]} \"Starbucks\" inputDomains.txt" 
        return 1
    fi
    if [[ "$#" -lt 3 ]]; then
        #input params
        whoisParam=""
        valueParam="$1"
        file="$2"
    else    
        whoisParam="$1"
        valueParam="$2"
        file="$3"
    fi


    IFS=$'\n';
    for value in $(cat "$file"); do 
        #echo "$value"
        whoisResult=$(whois "$value"|grep "$whoisParam"|grep -i "$valueParam")
        if [[ ${#whoisResult} -gt 0 ]]; then
            echo "$value has $valueParam"
        else
            echo -n "."
            #echo "$value has not $whoisParam/$valueParam"            
        fi
            
        sleep 0.35
    done
}

# This function extracts a domain from the program inscope 
# and calls amass to find other first level domains related to it. 
# you need to verify that the new domains belong to the target 
# try using filterByWhoisParam
getMoreInscope()
{
    if [[ -z "$1" ]]; then
        echo -en "\nUsage: ${FUNCNAME[0]} programName [CONFIG_FILE]\n\n"
        echo -en "Examples:\n"
        echo -en "  ${FUNCNAME[0]} programName      # Use default config file (~/amass_config.ini)\n"
        echo -en "  ${FUNCNAME[0]} programName /etc/amass_config.ini  # Use custom config file\n\n"
        return 1
    fi
    program="$1";
    domain=$(bbrf scope in --wildcard -p "$program"|sed 's/\*\.//g'| grep -v DEBUG|head -n 1)
    echo "Using $domain as domain"

    # Define config_file variable as an optional input parameter
    config_file=${2:-~/amass_config.ini}
    amass intel -config $config_file -d $domain -whois 
}

amassIntel() 
{
    if [[ -z "$1" ]]; then
        echo "Usage: amassIntel DOMAIN [CONFIG_FILE]"
        return 1
    fi

    domain=$1
    config_file=${2:-~/amass_config.ini}
    amass intel -config $config_file -d $domain -whois|sort 
}
