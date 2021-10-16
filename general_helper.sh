#general helper functions 
#create a screen instance with a given name
function createScreen()
{
    if [ -z "$1" ]
    then
      echo -e "#Creates a screen session with given name \n Use ${FUNCNAME[0]} SCREEN_NAME"
      return 1;
    fi

	screen -q -S "$1"
}

function getIp()
{
    if [ -z "$1" ]
    then
      echo -e "get Ip from domain\n Example: getIp example.com"
      return 1;
    fi
    dig $1 +short

}

# finds and then open a file with nano
locateNano()
{
    if [ -z "$1" ]
    then
      echo -e "Use ${FUNCNAME[0]} filename"
      return 1;
    fi
    search="$1"
    location=$(locate $search|head -n 1)
    #TODO choose from list when there are more than 1 result
    if [ ${#location} -gt 0 ]
    then
        nano $location
    else    
        echo "Not found: $search"
    fi
}
# finds and then open a file with nano
locateCat()
{
    if [ -z "$1" ]
    then
      echo -e "Use ${FUNCNAME[0]} filename"
      return 1;
    fi
    search="$1"
    location=$(locate $search|head -n 1 )
    #TODO choose from list when there are more than 1 result 

    if [ ${#location} -gt 0 ]
    then
        echo $location
        cat $location
        echo ""
    else
        echo "Not found: $search"
    fi
}
#use getField n (where n is the nth column)
# example:  cat file.txt | getField 4 
getField() 
{
    if [ -z "$1" ]
    then
      echo -e "Use ${FUNCNAME[0]} number (nth column)"
      echo "Example:  cat file.txt | getField 4"
      return 1;
    fi
    awk -v number=$1 '{print $number}'
    #this is an attempt to receive the separator as a function parameter 
    #awk -v column=$1 -v "field=$2" -F\\${field} '{print $column}' 
}
#get domain From URL
getDomainFromURL()
{
    url="$1"
    awk -F'/' <<<"$1" #'{print $1}' # | sed 's/http:\/\///;s|\/.*||'
}
#sort urls by TLD domain
sortByDomain()
{
    sed -e 's/^\([^.]*\.[^.]*\)$/.\1/'|sort -t . -k2|sed -e 's/^\.//'
} 


# This function allows to find the difference between to input/output files (containing domains or urls)
# Example if you ran bbrf urls multiple times and you want to output only the new urls
#1. bbrf urls > file1.txt
#some programs/urls were added
#2. bbrf urls > file2.txt
#using the function we can output only the new added content to the file

#diffFiles file1.txt file2.txt output.txt
diffFiles()
{
    if [ -z "$1" ] | [ -z "$2" ] | [ -z "$3" ]
    then
      echo "Use ${FUNCNAME[0]} file1.txt file2.txt output.txt"
      return 1;
    fi
    comm -3 <(sort $1) <(sort $2) > $3
}
#retreive the ORGs names in SSL Certs 
getOrgsFromCerts()
{
    if [ -z "$1" ] 
    then
      echo "Use ${FUNCNAME[0]} file.with.ssl.output.txt"
      return 1;
    fi

    names=( $@ )
    for file in "${names[@]}"
    do
        echo "$file"
        cat "$file" |grep -a subject |awk -F"O=" '{print $2}'|awk -F";" '{print $1}'|sort -u
    done
}
#retreive the ORGs names in SSL Certs 
getCNFromCerts()
{
    if [ -z "$1" ] 
    then
      echo "Use ${FUNCNAME[0]} file.with.ssl.output.txt"
      return 1;
    fi

    names=( $@ )
    for file in "${names[@]}"
    do
        echo "$file"
        cat "$file" |grep -a subject|awk -F"CN=" '{print $2}'|awk -F";" '{print $1}'|sort -u
    done
}

# Get all resolving Tls for a given domain name 
# For example, a program has a scope like companyA.*, we already know some domains companyA.com and companyA.fr, from here we could use all possible TLDs 
# to find new domains. This function first uses flat country TLDs and in a second iterating tests for com.tld (cases like com.ar, com.br, com.pe, etc)
getTLDs()
{
    URL="https://raw.githubusercontent.com/datasets/top-level-domain-names/master/top-level-domain-names.csv"
    if [ -z "$1" ] 
    then
        echo "Use ${FUNCNAME[0]} targetDomain"
        echo "Example ${FUNCNAME[0]} testing-sites"
        return 1;
    fi
    FILE="top-level-domain-names.csv"

    if [ -f "$FILE" ]; then
        echo "$FILE exists."
    #if file not found download it 
    else 
        echo "$FILE does not exist."
        echo "Downloading ... "
        curl -ks $URL -o $FILE
    fi

    target="$1"
    #do with com 
    tlds=$(grep country-code "$file" |awk -F "," '{print $1}'|grep -Pv '[^\x00-\x7F]'|awk -v target=$target '{print target$1}' |dnsx | awk '{print "*."$1}')
    echo "$tlds"

    # test them with com 
    target="$target".com
    tlds=$(grep country-code "$file" |awk -F "," '{print $1}'|grep -Pv '[^\x00-\x7F]'|awk -v target=$target '{print target$1}' |dnsx | awk '{print "*."$1}')
    echo "$tlds"
}
