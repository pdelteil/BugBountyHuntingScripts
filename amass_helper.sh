filterByWhoisParam()
{
 if [ -z "$1" ]  | [ -z "$2" ] 
    then
      echo -en "\nUse ${FUNCNAME[0]} whoisParam [optional] valueParam outputfile\n\n"
      echo "Example  ${FUNCNAME[0]} \"Tech Organization\" \"Starbucks\" inputDomains.txt" 
      echo "Example  ${FUNCNAME[0]} \"Starbucks\" inputDomains.txt" 
      return 1;
    fi

    #input params
    whoisParam="$1"
    valueParam="$2"
    file="$3"

    IFS=$'\n';
    for value in $(cat $file );
        do 
            #echo "$value"
            whoisResult=$(whois "$value"|grep "$whoisParam"|grep -i "$valueParam")
            if [ ${#whoisResult} -gt 0 ]
            then
                echo "$value"
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
 if [ -z "$1" ] 
    then
      echo -en "\nUse ${FUNCNAME[0]} programName\n\n"
      return 1;
    fi

    program="$1";
    domain=$(bbrf scope in -p "$program"|sed 's/\*\.//g'| grep -v DEBUG|head -n 1)
    echo "Using $domain as domain"
    amass intel -config ~/amass_config.ini -d $domain -whois #|awk '{print  "*."$1}
}

