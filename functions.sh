# shell script functions to be loaded on your bashrc file 

# creates a file with BBRF stats 
# The output is in the form 
#  program1, #domains, #urls
# Input parameter: filename
getBBRFStats()
{   
    IFS=$'\n'
    filename=$1
    for value in $(bbrf programs --show-disabled);
        do 
            echo "Getting stats of program $value"
            numUrls=$(bbrf urls -p "$value" | wc -l)
            numDomains=$(bbrf domains -p "$value" | wc -l)
            echo -e "$value, $numDomains,  $numUrls" >> $filename
    done
}

# displays all the disabled programs in BBRF
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
# This function allows to find the difference between to input/output files (containing domains or urls)
# Example if you ran bbrf urls multiple times and you want to output only the new urls
#1. bbrf urls > file1.txt
#some programs/urls were added 
#2. bbrf urls > file2.txt
#using the function we can output only the new added content to the file

#diffFiles file1.txt file2.txt output.txt
diffFiles()
{
    comm -3 <(sort $1) <(sort $2) > $3
}

# This function is used when adding a new program 
# it requires subfinder and assetfinder

getDomains()
{
    bbrf scope in --wildcard|bbrf inscope add -; 
    bbrf scope in --wildcard|bbrf domain add - --show-new; 
    bbrf scope in |bbrf domain add - --show-new; 
    bbrf scope in| subfinder -t 60 -silent |bbrf domain add - -s subfinder  --show-new; 
    bbrf scope in|assetfinder|bbrf domain add - -s assetfinder
}

# This function is used when adding a new program and after the getDomains function
# it requires httpx and httprobe
getUrls()
{
    RED="\e[31m"
    YELLOW="\e[33m"
    ENDCOLOR="\e[0m"

    #IFS=$'\n'
    doms=$(bbrf domains|grep -v DEBUG|tr ' ' '\n') 
    #echo $doms
    if [ ${#doms} -gt 0 ] 
        then
            echo -en "${RED} httpx domains${ENDCOLOR}\n"        
            echo "$doms" |httpx -silent -threads 100 |bbrf url add - -s httpx --show-new
            echo -en "${RED} httprobe domains${ENDCOLOR}\n"        
            echo "$doms" |httprobe -c 50 -prefer-https |bbrf url add - -s httprobe --show-new
    fi
}
#Use this function if you need to add several programs from a site
#You need to add Name, Reward, URL, inscope and outscope
#input platform/site
#Example  addPrograms intigriti 
addPrograms()
{
    RED="\e[31m"
    YELLOW="\e[33m"
    ENDCOLOR="\e[0m"

    if [ -z "$1" ]
    then
      echo "Use addPrograms platform (intrigriti, bugcrowd, h1, hackenproof, etc)"
      return 1;
    fi
    program=$1
    while true;
    do
        # Read the user input   
        site="$1"  
        echo -en "${YELLOW}Program name: ${ENDCOLOR}"  
        read program
        echo -en "${YELLOW}Reward? (1:money, 2:points, 3:thanks) ${ENDCOLOR} "
        read reward
        case $reward in
        1)    val="money";;
        2)    val="points";;
        3)    val="thanks";;
        esac
        echo -en "${YELLOW}Url?  ${ENDCOLOR} "
        read url

        bbrf new "$program" -t site:"$site" -t reward:"$val"  -t url:"$url"
        bbrf use "$program" 
    #echo -n "Creating $program in $site (default)"  
        echo ""
        IFS= read -r -p "$(echo -en $YELLOW" Add IN scope: "$ENDCOLOR)" wildcards
        #if empty skip
        if [ ! -z "$wildcards" ]
            then
                bbrf inscope add $wildcards 
            echo -n "Scope added \n"  

        else    
            echo -n "Empty!"
    fi         
    IFS= read -r -p "$(echo -en $YELLOW " Add OUT scope:" $ENDCOLOR)" oswildcards
    if [ ! -z "$oswildcards" ]
         then
             bbrf outscope add $oswildcards
             echo ""
             echo -ne "${YELLOW}out Scope added $oswildcards${ENDCOLOR}"  
         else
             echo -n "Empty!"
    fi
    echo ""
    echo -ne "${RED}Getting domains${ENDCOLOR}\n"; getDomains  
    echo -ne "${RED}Getting urls ${ENDCOLOR}\n"; getUrls  
    #echo -ne "${YELLOW}continue? (y/n)${YELLOW}" 
    #read cont
    #if [ "$cont" == "n" ]; then
    #        echo "exiting"
    #        exit
    #else 
    #    echo "" #"not n "
    #fi
    done
} 

removeURLsInChunks()
{
    size=$(bbrf urls|wc -l); 
    chunk=5000; 
    urls="1,${chunk}p" 
    parts=$((size%chunk?size/chunk+1:size/chunk)) 
    echo $parts ; 
    for i in $(seq 1 $parts)
        do echo "try $i"
        bbrf urls|sed -n "$urls"|bbrf url remove -
    done
}

#ADD URLS IN CHUNKS
addURLsInCHUNKS()
{
 if [ -z "$1" ] || [ -z "$2" ]
    then
      echo "Use addURLsInCHUNKS fileWithURLS PROGRAM"
      return 1;
    fi

RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
file=$1
program=$2
 size=$(cat $file |wc -l); 
 chunk=1000; 
 parts=$((size%chunk?size/chunk+1:size/chunk)) ; 
 echo $parts ;
 init=1
 end=$chunk
 for i in $(seq 1 $parts) ; 
    do
        echo "try $i"; 
        
        urls="${init},${end}p"; 
        sed -n "$urls" $file |httpx -silent -threads 500 |bbrf url add - -s httpx --show-new -p "$program"; 
        init=$(( $init + $chunk ))
        end=$(( $end + $chunk ))
    done
} 
#resolve domains IN CHUNKS
resolveDomainsInChunks()
{
 if [ -z "$1" ] || [ -z "$2" ]
    then
      echo "Use resolveDomainsInChunks fileUnresolvedDomains PROGRAM"
      return 1;
    fi

RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
file=$1
p=$2
 size=$(cat $file |wc -l); 
 echo $size
 chunk=100; 
 parts=$((size%chunk?size/chunk+1:size/chunk)) ; 
 echo $parts ;
 init=1
 end=$chunk
 for i in $(seq 1 $parts) ; 
    do
        echo "try $i"; 
        
        urls="${init},${end}p"; 
        #sed -n "$urls" $file    |dnsx -silent -a -resp | tr -d '[]' 
        #sed -n  "$urls" $file|awk '{print $1":"$2}' |bbrf domain update - -p "$p" -s dnsx 
        #>(awk '{print $1":"$2}' |bbrf domain update - -p "$p" -s dnsx) \
        #sed -n  "$urls" $file |awk '{print $1":"$2}' |bbrf domain add - -p "$p" -s dnsx --show-new
        sed -n  "$urls" $fil| awk '{print $2":"$1}' |bbrf ip add - -p "$p" -s dnsx
        #>(awk '{print $2":"$1}' |bbrf ip update - -p "$p" -s dnsx)
        
        #|httpx -silent -threads 500 |bbrf url add - -s httpx --show-new -p "$program"; 
        init=$(( $init + $chunk ))
        end=$(( $end + $chunk ))
  done
} 
