# shell script functions to be loaded on your bashrc file

# Set the text colors
RED=$(tput setaf 1) # red
YELLOW=$(tput setaf 3) # yellow
ENDCOLOR=$(tput sgr0) # reset text attributes

# Get the directory of the script
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "$script_dir"/general_helper.sh

AMASS_CONFIG="$HOME/amass_config.ini"
#update program data after outscope change 
#When you add a new outscope rule(s) you'd like that the program data gets updated
#this means removing domains and urls that now are out of scope
#This is something I need to do when I'm invited to a BBP that also has a VDP
#Example 
# > updateProgram notanIBMdomain.com IBM
updateProgram()
{
    if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} program rule"
        return 1
    fi

    #this should work for adding/removing a inscope rule 
    program="$1"
    rule="$2"
    #if rule is wildcard
    wildcard=$(echo "$rule"|grep '\*')

    if [[ ${#wildcard} -gt 0 ]]; then
        echo "has wildcard"
        rule2=$(echo "$rule"|sed 's/*\.//g')
    else
        rule2="*.$rule"
    fi
    #check if the program has that rule 
    check=$(bbrf show "$program" | grep -i "$rule")
    #careful when the removed url is a subdomain of a wildcard rule

    if [[ ${#check} -gt 0 ]]; then
        echo "Rule $rule found in program $program"
        #removing rule from program
        #stats before removing
        inscopeRules=$(bbrf show "$program"|jq '.inscope'|grep '"'|wc -l)
        domains=$(bbrf domains -p "$program"|wc -l)
        urls=$(bbrf urls -p "$program"|wc -l)
        echo "Stats before update inscope rules: $inscopeRules, domains: $domains,  urls: $urls"
        echo -ne "${RED}Removing inscope rule${ENDCOLOR}\n"
        yes|bbrf inscope remove "$rule" "$rule2" -p "$program"
        #removing wildcard
        rule=$(echo "$rule"|sed 's/*\.//g')
        #removing domains
        echo "Removing domains"
        bbrf domains -p "$program"|grep -i "$rule" | bbrf domain remove - -p "$program"
        #remove urls
        echo "Removing urls"
        bbrf urls -p "$program"|grep -i "$rule" |bbrf url remove -  #we don t need program here
    
    else
        echo "rule $rule not in program $program"
        return -1
    fi

    #show stats after removing urls and domains
    inscopeRules=$(bbrf show "$program"|jq '.inscope'|grep '"'|wc -l)
    domains=$(bbrf domains -p "$program"|wc -l)
    urls=$(bbrf urls -p "$program"|wc -l)
    echo "Stats after update  inscope rules: $inscopeRules, domains: $domains,  urls: $urls"
}

#disable all programs from a given list (file)
#example of use, disable all for points/thanks programs
#  use > cat programs| disablePrograms
disablePrograms()
{
    while read -r data; do
        echo  "disabling $data"
        bbrf disable "$data" 
    done

}
# creates a file with BBRF stats in CSV format (using ; as separator)
# By default outputs all programs including the ones with no defined inscope.
# Use the -nd flag to output only enabled programs

# Examples 
# > getStats bbrf.stats.csv  #all programs 
# > getStats bbrf.stats.enabled.csv -nd #all programs excluding disabled ones
# TODO Include flags to choose whether to include #domains, #urls or #ips
getStats()
{   
    if [[ -z "$1" ]] || [[ "$2" != "-nd"  &&  -n "$2" ]]; then
        echo "Use ${FUNCNAME[0]} outputfile.csv -nd (not to include disabled programs)"
        return 1
    fi
    if [[ "$2" == "-nd" ]]; then
        param=""
    else 
        param="--show-disabled"
    fi
    IFS=$'\n'
    filename="$1"
    
    # Headers
    headers="Program; Site; Program url; disabled; reward; author; notes; added Date; gov; #domains; #urls; #IPS; #inscope; #inscopeWildcard" 
    echo -e "$headers" >> "$filename"
    echo "Getting stats of programs $param"
    
    allPrograms=$(bbrf programs $param --show-empty-scope)
    numberPrograms=$(echo "$allPrograms"|wc -l)
    #counter
    i=1
    for program in $(echo "$allPrograms"); do 
        echo -en "${YELLOW}($i/$numberPrograms)${ENDCOLOR} $program\n"

        # Fields/columns
        description=$(bbrf show "$program")
        site=$(echo "$description" | jq -r '.tags.site')
        reward=$(echo "$description" | jq -r '.tags.reward')
        programUrl=$(echo "$description" | jq -r '.tags.url')
        disabled=$(echo "$description" | jq -r '.disabled')
        author=$(echo "$description" | jq -r '.tags.author')
        notes=$(echo "$description" | jq -r '.tags.notes') 
        addedDate=$(echo "$description" | jq -r '.tags.addedDate')
        gov=$(echo "$description" | jq -r '.tags.gov')

        # Metrics 
        numUrls=$(bbrf urls -p "$program"|wc -l)
        numDomains=$(bbrf domains -p "$program"|wc -l)
        #numIPs=$(bbrf ips -p "$program"|wc -l)
        numInScope=$(bbrf scope in -p "$program"|wc -l)
        numInScopeWildcard=$(bbrf scope in --wildcard -p "$program"|wc -l)
        values="$program; $site; $programUrl; $disabled; $reward; $author; $notes; $addedDate; $gov; $numDomains; $numUrls; $numIPs;$numInScope; $numInScopeWildcard"
        echo -e "$values" >> $filename
        i=$(( $i + 1))
    done
}


# The objetive is to get subdomains using different tools and adding the results to BBRF 
# Examples 
# Recon subdomains for active BBRF program
# > getDomains 
# Recon subdomains for testProgram
# > getDomains -p testProgram 
# Output results to file instead of BBRF.
# > getDomains -f outputFile.txt 
getDomains()
{
    #thread configs
    dnsxThreads=200
    subfinderThreads=100
    gauThreads=30
    #no params
    flag="$1"
    params=""
    
    if [[ -z $flag ]]; then
        echo -ne "${YELLOW} Running bbrf mode ${ENDCOLOR}\n"
    elif [[ $flag == "-f" ]]; then
        if [[ -n "$2" ]]; then
            file="$2"
            tempFile="/tmp/$file.temp"
            echo -ne "${YELLOW} Running filemode ${ENDCOLOR}\n"
            echo -ne "${YELLOW}    Writing results to $tempFile  ${ENDCOLOR}\n"
            fileMode=true
        else
            echo -ne "${YELLOW} Filename needed!${ENDCOLOR}\n"
            echo -ne "${YELLOW} Use getDomains -f filename.ext ${ENDCOLOR}\n"
            return -1
        fi
    elif [[ $flag == "-p" ]]; then
        if [[ -n "$2" ]]; then
            params="-p$2"
            #check if program exists
            show=$(showProgram "$2")
            #stores the return value of the showProgram function
            status=$(echo $?)
            if [[ "$status" != "0" ]]; then
                echo -ne "${RED}Program $2 does not exists!${ENDCOLOR}\n"
                return 1
            fi    

        else
            echo "add Program name!"
            echo "Use: getDomains -p program "
            return -1
        fi
    fi

    IFS=$'\n'
    scopeIn=$(bbrf scope in $params)
    echo "$scopeIn"|bbrf domain add - $params --show-new
    wild=$(bbrf scope in --wildcard $params| grep -v DEBUG)
    if [[ ${#wild} -gt 0 ]]; then
        echo "$wild"|bbrf inscope add - $params
        echo "$wild"|bbrf domain add - $params --show-new

        echo -ne "${RED} Running amass ${ENDCOLOR}\n"
        if [ -f "$AMASS_CONFIG" ]; then
            :  #echo -ne "\t ${YELLOW} amass using $AMASS_CONFIG config file\n${ENDCOLOR}"
        else
            echo -ne "\t${RED} amass not using a config file, $AMASS_CONFIG not found\n${ENDCOLOR}"
        fi

        if [[ "$fileMode" = true ]] ; then
            for domain in $(echo "$wild"); do
                echo -ne "${YELLOW}  Querying $domain ${ENDCOLOR}\n"
                amass enum -d $domain -config $AMASS_CONFIG -passive 2>/dev/null | dnsx -t $dnsxThreads -silent |tee --append "$tempFile-amass.txt"
            done
            else
                for domain in $(echo "$wild"); do
                    echo -ne "${YELLOW}  Querying $domain ${ENDCOLOR}\n"
                    amass enum -d $domain -config $AMASS_CONFIG -passive 2>/dev/null | dnsx -t $dnsxThreads -silent | bbrf domain add - -s amass $params --show-new
                done
            fi
            echo -ne "${RED} Running subfinder ${ENDCOLOR}\n"
            if [[ "$fileMode" = true ]]; then
                echo "$wild"|subfinder -all -t $subfinderThreads -silent |dnsx -t $dnsxThreads -silent |tee --append "$tempFile-subfinder.txt"
            else
                echo "$wild"|subfinder -all -t $subfinderThreads -silent |dnsx -t $dnsxThreads -silent |bbrf domain add - -s subfinder $params --show-new
            fi
 
            echo -ne "${RED} Running assetfinder ${ENDCOLOR}\n"
            if [[ "$fileMode" = true ]]; then
                echo "$wild"|assetfinder|dnsx -t $dnsxThreads -silent|tee --append "$tempFile-assetfinder.txt"
            else
                echo "$wild"|assetfinder|dnsx -t $dnsxThreads -silent|bbrf domain add - -s assetfinder $params --show-new
            fi

            echo -ne "${RED} Running gau ${ENDCOLOR}\n"
            if [[ "$fileMode" = true ]] ; then
                gau --subs "$wild" --threads $gauThreads| unfurl -u domains | dnsx -t $dnsxThreads -silent| tee --append "$tempFile-gau.txt"
             else
                gau --subs "$wild" --threads $gauThreads| unfurl -u domains | dnsx -t $dnsxThreads -silent| bbrf domain add - -s gau $params --show-new
            fi

            echo -ne "${RED} Running waybackurls ${ENDCOLOR}\n"
            if [[ "$fileMode" = true ]] ; then
                echo "$wild"| waybackurls| unfurl -u domains| dnsx  -t $dnsxThreads -silent| tee --append "$tempFile-waybackurls.txt"
             else
                echo "$wild"| waybackurls| unfurl -u domains| dnsx  -t $dnsxThreads -silent| bbrf domain add - -s waybackurls $params --show-new
            fi
   fi
}

# This function is used when adding a new program and after the getDomains function
# getUrls PROGRAM
# it requires httpx and httprobe
getUrls()
{
    threads=150
    if [[ -z "$1" ]]; then
        doms=$(bbrf domains|grep -v DEBUG|tr ' ' '\n')
    else    
        program="$1"
        doms=$(bbrf domains -p "$program"|grep -v DEBUG|tr ' ' '\n')
    fi
    if [[ ${#doms} -gt 0 ]]; then
        numDomains=$(echo "$doms"|wc -l)
        echo -en "${RED} Using httpx in $numDomains domains (threads: $threads)${ENDCOLOR}\n"
        echo "$doms"|httpx -silent -threads $threads|bbrf url add - -s httpx --show-new
        echo -en "${RED} Using httprobe in $numDomains domains (threads: $threads)${ENDCOLOR}\n"
        echo "$doms"|httprobe -c $threads --prefer-https|bbrf url add - -s httprobe --show-new
    fi
}
# Use this function if you need to add several programs from a site
# You need to add Name, Reward, URL, inscope and outscope
# input platform/site
# Example addPrograms intigriti hunter
addPrograms()
{
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
      echo -ne "Use ${FUNCNAME[0]} site author\nExample ${FUNCNAME[0]} h1 hunter\nExample ${FUNCNAME[0]} bugcrowd hunter\n"
      return 1
    fi
    unset IFS
    while true; do
        # Read user's input
        site="$1"
        author="$2"
        addedDate=$(date +%D-%H:%M)
        echo -en "${YELLOW}Program name: ${ENDCOLOR}"
        read program
        program=$(echo $program|sed 's/^ *//;s/ *$//')
        echo -en "${YELLOW}Reward? (1:money[default:press Enter], 2:points, 3:thanks) ${ENDCOLOR}"
        read reward
        case $reward in
            1 )    val="money";;
            2 )    val="points";;
            3 )    val="thanks";;
            "")    val="money";;
        esac
        echo -en "${YELLOW}Public or private? (1:public[default:press Enter], 2:private)${ENDCOLOR}"
        read public
        case $public in 
            1)    val_public="true";;
            2)    val_public="false";;
           "")    val_public="true";;
        esac
        echo -en "${YELLOW}Url? ${ENDCOLOR} "
        # TODO create tentative url combining site + program name
        read url
        #recon true means the scope is not bounded or clear
        #If you could spend more time/resources doing more specific recon
        echo -en "${YELLOW}Recon? ${ENDCOLOR} (0:false[default:press Enter], 1:true) "
        read recon
        case $recon in 
            0)    val_recon="false";;
            1)    val_recon="true";;
           "")    val_recon="false";;
        esac
        echo -en "${YELLOW}Android app? ${ENDCOLOR} (0:false[default:press Enter], 1:true) "
        read android
        case $android in 
             0)    val_android="false";;
             1)    val_android="true";;
             "")   val_android="false";;
        esac
        echo -en "${YELLOW}iOS app? ${ENDCOLOR} (0:false[default:press Enter], 1:true) "
        read iOS
        case $iOS in 
             0)    val_iOS="false";;
             1)    val_iOS="true";;
            "")    val_iOS="false";;
        esac
        echo -en "${YELLOW}Source code? ${ENDCOLOR} (0:false[default:press Enter], 1:true) "
        read source
        case $source in 
            0)    val_source="false";;
            1)    val_source="true";;
            "")   val_source="false";;
        esac
        echo -en "${YELLOW}Has API? ${ENDCOLOR} (0:false[default:press Enter], 1:true) "
        read api
        case $api in 
            0)    val_api="false";;
            1)    val_api="true";;
            "")   val_api="false";;
        esac
        if $val_api; then
            echo -en "${YELLOW}APi endpoints? ${ENDCOLOR} "
            read api_endpoints
        fi
        echo -en "${YELLOW}Requires VPN? ${ENDCOLOR} (0:false[default:press Enter], 1:true) "
        read vpn
        case $vpn in 
            0)    val_vpn="false";;
            1)    val_vpn="true";;
            "")   val_vpn="false";;
        esac
        echo -en "${YELLOW}CIDR? ${ENDCOLOR} (0:false[default:press Enter], 1:true) "
        read cidr
        case $cidr in 
            0)    val_cidr="false";;
            1)    val_cidr="true";;
            "")   val_cidr="false";;
        esac
        if $val_cidr; then
            #input comma separated values in the CIDR notation (IP/netmask, ie: 198.51.100.0/22)
            echo -en "${YELLOW}CIRD Ranges? ${ENDCOLOR}"
            read cidr_ranges
        fi

        echo -en "${YELLOW}Notes/Comments? ${ENDCOLOR} (press enter if empty)"
        read notes

        result=$(bbrf new "$program" -t site:"$site" -t reward:"$val" -t url:"$url" -t recon:"$val_recon" \
                 -t android:"$val_android" -t iOS:"$val_iOS" -t sourceCode:"$val_source" -t addedDate:"$addedDate" \
                 -t author:"$author" -t notes:"$notes" -t api:"$val_api" -t api_endpoints:"$api_endpoints" \
                 -t public:"$val_public" -t vpn:"$val_vpn" -t cidr:"$val_cidr" -t cidr_ranges:"$cidr_ranges")

        if [[ $result == *"conflict"* ]]; then
            echo -ne "${RED}Program already on BBRF!${ENDCOLOR}\n"
            showProgram "$program"
            return 1
        fi
        echo -en "${YELLOW} Add IN scope: ${ENDCOLOR}\n"
        read -r inscope_input
        #if empty skip
        if [[ ! -z "$inscope_input" ]];   then
            bbrf inscope add $inscope_input -p "$program"
            echo -ne "${RED} inscope: \n"
            #just to check everything went well
            bbrf scope in -p "$program"
            echo -ne "${ENDCOLOR}\n"
        fi
        # if inscope has no wildcards dont ask for outscope
        if [[ "$inscope_input" == *\*.* ]]; then
            echo -en "${YELLOW} Add OUT scope: ${ENDCOLOR}\n" 
            read -r outscope_input
            #if empty skip
            if [[ ! -z "$outscope_input" ]]; then
               bbrf outscope add $outscope_input -p "$program"
               echo -ne "${RED} outscope: \n"
               #just to check everything went well
               bbrf scope out -p "$program"
               echo -ne "${ENDCOLOR}\n"  
            fi
        fi
        if [[ ${#inscope_input} -gt 0 ]]; then
            echo -ne "${RED}Getting domains${ENDCOLOR}\n"
            getDomains  
            echo -ne "${RED}Getting urls ${ENDCOLOR}\n"
            getUrls  
            #getIPs
            #scanPorts
            #run nuclei
            numUrls=$(bbrf urls|wc -l) 
            if [[ "$numUrls" -gt 0 ]]; then
                echo -ne "${YELLOW} Run nuclei? [urls: $numUrls] (y/n)[default:no, press Enter]${ENDCOLOR} "
                read runNuclei
                case $runNuclei in
                    "yes")    valRunNuclei="true";;
                    "y"  )    valRunNuclei="true";;
                    "n"  )    valRunNuclei="false";;
                    "no" )    valRunNuclei="false";;
                    ""   )    valRunNuclei="false";;
                esac
    
                if [[ "$valRunNuclei" == "true" ]]; then
                    echo -ne "\n${RED}Running nuclei${ENDCOLOR}\n"
                    bbrf urls | nuclei -t ~/nuclei-templates -es info,unknown -stats -si 180 -itags fuzz,dos -eid weak-cipher-suites,mismatched-ssl,expired-ssl,self-signed-ssl
                fi
            fi
        fi
    done
} 

# It is faster to remove urls in chunks than directly 
# works for the current active program
# in the case of URLs and IP the program is not mandatory, it will delete everything in the input file
removeInChunks()
{
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "To remove domains use ${FUNCNAME[0]} fileWithDomains domains chunckSize (optional:default 1000)"
        echo "To remove urls use ${FUNCNAME[0]} fileWithUrls urls chunkSize (optional:default 1000)"
        echo "To remove ips use ${FUNCNAME[0]} fileWithIPs ips chunkSize (optional:default 1000)"
        return 1
    fi
    
    #input vars
    file="$1"
    type="$2"
    chunkSize="$3"

    if [[ "$type" ==  "domains" ]] || [[ "$type" == "urls" ]]  || [ "$type" == "ips" ]]; then
        echo "" 
    else
        echo " use domains, ips or urls "
        return 1
    fi

    size=$(cat "$file"|wc -l) 
    echo "Size "$size
    #default value for chunk size
    if [[ -z "$chunkSize" ]]; then
        chunkSize=1000
    fi
    parts=$((size%chunkSize?size/chunkSize+1:size/chunkSize))

    echo "Chunk size "$chunkSize
    echo "Chunks "$parts
    init=1
    end=$chunkSize

    for i in $(seq 1 $parts); do
        echo "Removing chunk $i/$parts"
        element="${init},${end}p"; 

        if [[ "$type" == "urls" ]]; then
            sed -n "$element" "$file"|bbrf url remove - 
        elif [[ "$type" == "domains" ]]; then
           sed -n "$element" "$file"|bbrf domain remove - 
        elif [ "$type" == "ips" ]]; then
           sed -n "$element" "$file"|bbrf ip remove -
        fi
        init=$(( $init + $chunkSize ))
        end=$(( $end + $chunkSize ))
    done
}

# This function solves the problem of adding a big amount of urls or domains, often times the couchdb server will crash with an 'unknown_error'
# 1. ADD Domains IN CHUNKS from FILE containing domains 
# 2. Add URLs to program probing domains from FILE containing domains
# the chunk size depends on your bbrf (couchdb) server capacity 
addInChunks()
{
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo -ne "To add domains use ${YELLOW}${FUNCNAME[0]} fileWithDomains domains chunckSize (optional:default 1000) source (optional) resolve ${ENDCOLOR}\n"
        echo -ne "To add urls use ${YELLOW}${FUNCNAME[0]} fileWithUrls urls chunkSize (optional:default 1000) source (optional)${ENDCOLOR}\n"
        echo -ne "Examples\n"
        echo "addInChunks domains.txt domains "" "" resolve"
        echo "addInChunks domains.txt domains "" source resolve"
        return 1
    fi
    #input vars
    file="$1"
    type="$2"
    chunkSize=${3:-1000}
    source=${4:-" no source "}
    resolve=${5:-"no"}

    #TODO reverse if logic 	
    if [[ "$type" ==  "domains" ]] || [[ "$type" == "urls" ]]; then
        echo "" 
    else
        echo " use domains or urls "
        return 1
    fi

    size=$(cat "$file"|wc -l)
    echo "Size "$size
    echo "Chunk size "$chunkSize
    parts=$((size%chunkSize?size/chunkSize+1:size/chunkSize))
    echo "Chunks "$parts
    init=1
    end=$chunkSize

    for i in $(seq 1 $parts); do
        echo -ne "${YELLOW}Adding chunk $i/$parts${ENDCOLOR}\n"
        elements="${init},${end}p" 

        if [[ "$type" == "urls" ]]; then
            sed -n "$elements" "$file"|bbrf url add - -s "$source" --show-new -p@INFER
        else
    	    if [[ "$resolve" == "resolve" ]]; then 
	            sed -n "$elements" "$file"|dnsx -silent|bbrf domain add - -s "$source" --show-new -p@INFER
    	    else 
    	        sed -n "$elements" "$file"|bbrf domain add - -s "$source" --show-new -p@INFER
    	    fi 
        fi
        init=$(( $init + $chunkSize ))
        end=$(( $end + $chunkSize ))
    done
} 
#resolve domains IN CHUNKS
#This function allows to add ip addresses in chunks. 
resolveDomainsInChunks()
{
 if [[ -z "$1" ]] || [[ -z "$2" ]]; then
      echo "Use ${FUNCNAME[0]} fileUnresolvedDomains"
      return 1
    fi

 file=$1
 size=$(cat $file |wc -l) 
 echo $size
 chunk=100
 parts=$((size%chunk?size/chunk+1:size/chunk))
 echo $parts
 init=1
 end=$chunk
 for i in $(seq 1 $parts); do
    echo "try $i"
    
    urls="${init},${end}p"
    #sed -n "$urls" $file    |dnsx -silent -a -resp | tr -d '[]' 
    #sed -n  "$urls" $file|awk '{print $1":"$2}' |bbrf domain update - -p "$p" -s dnsx 
    #>(awk '{print $1":"$2}' |bbrf domain update - -p "$p" -s dnsx) \
    #sed -n  "$urls" $file |awk '{print $1":"$2}' |bbrf domain add - -p "$p" -s dnsx --show-new
    sed -n  "$urls" $file| awk '{print $2":"$1}' |bbrf ip add - -p@INFER -s dnsx
    #>(awk '{print $2":"$1}' |bbrf ip update - -p "$p" -s dnsx)
        
    #|httpx -silent -threads 500 |bbrf url add - -s httpx --show-new -p "$program"; 
    init=$(( $init + $chunk ))
    end=$(( $end + $chunk ))
  done
} 
#Checks if a program exists based on part of the name
# Example
# checkProgram hackerone 
# checkProgram hacker  #all programs containing hacker in the program's name
checkProgram() {
  # Check if an argument was provided
  if [[ -z "$1" ]]; then
    # If no argument was provided, print an error message and exit the function
    echo "Use ${FUNCNAME[0]} text"
    echo "To display the detail of the program found (only if exact match was found)"
    echo "Use ${FUNCNAME[0]} text -show"
    return 1
  fi

  # Set the text variable to the argument provided
  text="$1"
  
  # Search for programs matching the text provided
  programs=$(bbrf programs --show-disabled --show-empty-scope)

  if [[ "$programs" =~ "unauthorized" ]]; then
        echo -en "${RED}BBRF unauthorized! Check user/password\n${ENDCOLOR}"
        return 1
  fi
  programs=$(echo "$programs"|grep -i "$text")
  #output header
  result="Program Name;Site\n"
  if [ -z "$programs" ]; then
      count=0
  else
      # Count the number of lines in $output using 'wc' command
      count=$(echo  "$programs" | wc -l)
  fi

  # Check if the line count is 1
  if [ "$count" -eq 1 ]; then
    showProgram "$programs"
    return 1
  fi
  while IFS= read -r line; do
    # Process each line of the output
    site=$(bbrf show "$line"|jq|grep site|awk -F":" '{print $2}'|tr -d ",\" ")
    #echo "$line;$site"
    result+="$line;$site\n"
  done <<< "$programs"
  # If more than 1 program was found, print them
  if [[ ${#programs} -gt 1 ]]; then
      program=$(echo -e "$result")
      print_table "$program"
  # If no programs were found, print an error message
  else    
    echo -ne "${RED}No programs found! ${ENDCOLOR}\n\n"
  fi
}

#finds the program name from a domain, URL or IP Adress. 
#Useful when you find a bug but you don't know where to report it (what programs it belongs to). 
# Examples
# findProgram http://www.hackerone.com 
# findProgram www.hackerone.com 
# findProgram 104.16.99.52

findProgram()
{
    INPUT=$(echo "$1"|sed -e 's|^[^/]*//||' -e 's|/.*$||') #in case the input has a trailing / 
    if [[ -z "$INPUT" ]]; then
      echo "Use ${FUNCNAME[0]} URL, domain or IP Address"
      return 1
    fi
    show=$(bbrf show "$INPUT") 

    if [[ "$show" =~ "unauthorized" ]]; then
        echo -en "${RED}BBRF unauthorized! Check user/password\n${ENDCOLOR}"
        return 1
    fi
    
    program=$(echo "$show" |jq -r '.program')

    #case input is an IP
    if [[ $INPUT =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        domains=$(echo $show |jq -r '.domains'|grep "\."|tr -d '"')
        echo -en "\n${YELLOW} Domains: $domains${ENDCOLOR}\n"
        show=$(bbrf show "$program")
    fi

    if [[ ${#program} -gt 0 ]]; then
        output=$(show_program_tags "$program")
        print_table "$output"
  
    else
        echo -ne "${RED}No program found!${ENDCOLOR}\n\n"
    fi
}

# Lists all key values of a given tag 
# Examples
# > listTagValues program
# TODO list all tags and select one 
listTagValues()
{   
    if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} TagName"
        return 1
    fi

    tag="$1"
    IFS=$'\n'
    for program in $(bbrf programs --show-disabled); do 
        key=$(bbrf show "$program"|jq '.tags.site')
        echo -n '.'
        keys+=("$key") 
    done
    #show unique key values
    keyValues=$(echo "${keys[@]}" | tr ' ' '\n' | sort -u)
    echo "$keyValues"
    
}

# sets debug mode on or off
debugMode()
{
    configFile="$HOME/.bbrf/config.json"

    #detect if debug mode is not set in config file 
    debug=$(grep '"debug"' $configFile)
    #debug word not found in config file

    if [[ ${#debug} == 0 ]]; then
        sed -i 's/}/,"debug": true}/g' $configFile
    fi
    if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} false/true"
        return 1
    fi
    if [[ "false" == "$1" ]]; then
        echo "Setting BBRF debug mode off"
        sed -i 's/"debug": true/"debug": false/g' $configFile
     elif [[ "true" == "$1" ]]; then
        echo "Setting BBRF debug mode on"
        sed -i 's/"debug": false/"debug": true/g' $configFile
     else  
        echo "Use ${FUNCNAME[0]} false/true"   
     fi  

}
# displays active program
showActiveProgram()
{
    configFile="$HOME/.bbrf/config.json"

    program=$(cat $configFile | jq | grep "program"| awk -F":" '{print $2}'| tr -d "," | tr -d '"' \
                              |sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
 
    echo "$program" 

}
# displays details of a given program
showProgram()
{
    if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} programName -stats [optional, displays number of urls and domains]"
        return 1
    fi
    program="$1"
    output=$(show_program_tags "$program")
    flag="$2" 

    #case but no flag stats
    if [[ ${#output} -gt 0 ]]; then
        #output=$(echo "$output"|tr -d ":\",{}[]")
        print_table  "$output"
        #print_lines_in_colors "$output" 
     if [[ "$flag" != "-stats" ]]; then
        return 0
     fi
    else    
        echo -ne "${RED}$program not found! ${ENDCOLOR}\n\n"
        #error
        return 1
    fi

    if [[ -z "$flag" ]]; then    
        return 1
    fi
   
    if [[ "$flag" == "-stats" ]]; then
        echo -en "Calculating stats for $program ...\n"
        domains=$(bbrf domains -p "$program"|wc -l )
        urls=$(bbrf urls -p "$program"|wc -l) 
        echo -en "\n${YELLOW}Domains: "$domains "\n"
        echo -en "Urls: "$urls"${ENDCOLOR}\n"
        return 0
    else
        echo "Use ${FUNCNAME[0]} programName -stats [optional, displays number of urls and domains] "
        return 1
    fi
}

# adds IPs from a CIDR to a program
#example addIPsFromCIDR 128.177.123.72/29 program
addIPsFromCIDR()
{
    if [[ -z "$1" ]] | [[ -z "$2" ]]; then
        echo "Use ${FUNCNAME[0]} 128.177.123.72/29 program"
        return 1
    fi

    CIDR="$1"
    program="$2"
    #params are just to speed up ping
    fping -t 5 -r 1  -b 1 -g $CIDR 2> /dev/null|awk '{print $1}'|bbrf ip add - -p $program --show-new
}
#this function is especific for my implementation. 
# Examples

# get domains from enabled programs and not gov programs
# > getBugBountyData domains

# get domains from enabled and disabled programs and not gov programs
# > getBugBountyData domains -d

# get urls from enabled programs and not gov programs
# > getBugBountyData urls

# get IPs from enabled programs and not gov programs
# > getBugBountyData ip

# get in scope from enabled programs and not gov programs
# > getBugBountyData inscope

# get out scope from enabled programs and not gov programs
# > getBugBountyData outscope

# TODO: include flag to retrieve all programs, this is only useful for inscope or outscope
getBugBountyData()
{
    local param=""
    if [[ "$1" != "domains"  &&  "$1" != "urls" && "$1" != "ips" && "$1" != "inscope" && "$1" != "outscope" ]] \
       || [[ "$2" != "-d"  &&  -n "$2" ]] ; then
        echo -en "${YELLOW}Use ${FUNCNAME[0]} domains, urls, ips, inscope, outscope "
        echo -en "(Add -d to include disabled programs)${ENDCOLOR}\n"
        return 1 
    elif [[ "$2" == "-d" ]]; then
        param="--show-disabled"
        echo -ne "${RED}Including disabled programs${ENDCOLOR}\n"
    fi

    # Set the value of the "data" array based on the value of the first argument
    data=("$1")

    if [[ "$1" == "inscope" ]]; then
        #will output only inscope with a wildcard, ie *.domain.com
        data=("scope" "in" "--wildcard")    
    fi
    if [[ "$1" == "outscope" ]]; then
        data=("scope" "out")
    fi

    # Get a list of all bug bounty programs
    allPrograms=$(bbrf programs $param)

    IFS=$'\n'
    for program in $(echo "$allPrograms"); do

        # Get the description of the current program
        description=$(bbrf show "$program")

        # Check if the program is a government program
        gov=$(echo "$description"  |jq -r '.tags.gov')
        # If the program is not a government program, retrieve the data
        if [[ "$gov" != "true" ]]; then
            bbrf ${data[@]} -p "$program"
        fi   
    done
}

#Get all urls from programs with a specific tag value
# Examples
# get all urls from Intigriti programs
# > getUrlsWithProgramTag site intigriti  

# get all urls from bugcrowd programs
# > getUrlsWithProgramTag site bugcrowd

# get all urls from paid programs
# > getUrlsWithProgramTag reward money

getUrlsWithProgramTag()
{   
    if [[ -z "$1" ]] | [[ -z "$2" ]]; then
        echo "Use ${FUNCNAME[0]} tag value"
        echo "Example ${FUNCNAME[0]} site intigriti"
        return 1
    fi

    TAG="$1"
    VALUE="$2"
    allPrograms=$(bbrf programs where $TAG is $VALUE)
  
    for program in $(echo "$allPrograms"); do
        bbrf urls -p "$program"
    done
}

# retrieve programs data (type, with values 'inscope', 'outscope', 'urls', 'domains', 'ips') 
# based on 2 conditions: site (intigriti, bugcrowd, h1, etc) and reward (money, points, thanks) 
# getProgramData bugcrowd money names
# getProgramData bugcrowd points urls
getProgramData() {
  rewards=(money points thanks)
  # Check if required arguments are provided
  if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]]; then
    output=("Usage: ${FUNCNAME[0]} SITE REWARD TYPE" "  SITE: (intigriti, bugcrowd, h1, yeswehack or all)" "  REWARDS: (money, points, thanks or all)" \
            "  TYPE: (inscope, outscope, urls, domains, ips)" "    Example: ${FUNCNAME[0]} bugcrowd money names" "             ${FUNCNAME[0]} bugcrowd points urls" "             ${FUNCNAME[0]} all points inscope")
    for line in "${output[@]}"; do
        # Print the line with a different color on each iteration
        if [ $((i % 2)) -eq 0 ]; then
            echo "${RED}$line${ENDCOLOR}"
        else
            echo "${YELLOW}$line${ENDCOLOR}"
        fi
        i=$((i + 1))
    done
    return 1
  fi

  # Assign provided arguments to variables
  local site="$1"
  local reward="$2"
  local type="$3"

  # Set data array based on type
  local data
  case "$type" in
    inscope)
      echo -e "Getting inscope data" >&2
      data=("scope" "in" "--wildcard")
      ;;
    outscope)
      echo -e "Getting outscope data" >&2
      data=("scope" "out")
      ;;
    urls)
      echo -e "Getting url data" >&2
      data=("urls")
      ;;
    domains)
      echo -e "Getting domain data" >&2
      data=("domains")
      ;;
    ips)
      echo -e "Getting IP data" >&2
      data=("ips")
      ;;
    names)
      echo -e "Getting programs names" >&2
      data=("")
      ;;
    *)
      echo -e "Invalid type provided. Valid options are: names, inscope, outscope, urls, domains, ips" >&2
      return 1
      ;;
  esac
  echo "$data"
  IFS=$'\n'

  if [[ "$site" == "all" ]] && [[ "$reward" != "all" ]]; then
      local allPrograms=$(bbrf programs where reward is "$reward")
  
  elif [[ "$site" == "all" ]] && [[ "$reward" == "all" ]]; then
      for ((i=0; i< ${#rewards[@]}; i++)); do
          temp=$(echo "${rewards[$i]}")
          programs=$(bbrf programs where reward is "$temp")
          allPrograms+="$programs "
      done
  
  else
      # Get all programs for the provided site
      local allPrograms=$(bbrf programs where site is "$site")
  fi

  # Loop through programs and get data based on type and reward
  for program in $(echo "$allPrograms"); do
    local description=$(bbrf show "$program")
    local rewardInfo=$(echo "$description" | jq -r '.tags.reward')

    if [[ "$type" == "names" ]]; then
      local url=$(echo "$description" | jq -r '.tags.url')
      if [[ "$rewardInfo" == "$reward" ]] || [[ "$reward" == "all" ]]; then
        echo "$program, $url"
      fi
    # different the names 
    elif [[ "$rewardInfo" == "$reward" ]] || [[ "$reward" == "all" ]]; then
      bbrf "${data[@]}" -p "$program"
    fi
  done
}

#remove all urls from a program
# Examples
# removes all urls from AT&T program
# > removeUrls ATT  
removeUrls()
{
    if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} program"
        echo "Example ${FUNCNAME[0]} IBM"
        return 1
    fi

    PROGRAM="$1"
    bbrf urls -p "$PROGRAM"|bbrf url remove -
}
#remove domains from a program
# Examples
# removes all domains from AT&T program
# > removeDomains ATT
removeDomains()
{
    if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} program"
        echo "Example ${FUNCNAME[0]} IBM"
        return 1
    fi

    PROGRAM="$1"
    bbrf domains -p "$PROGRAM"|bbrf domain remove -
}

#remove inscope from a program
# then removing domains and urls is needed
removeInScope() {

  # Print usage message if no arguments are provided
  if [[ -z "$2" ]]; then
    echo "Use ${FUNCNAME[0]} program [-all|inscope rule]"
    echo "Example ${FUNCNAME[0]} IBM [-all]"
    echo "Example ${FUNCNAME[0]} IBM *.ibm.com"
    return 1
  fi

  PROGRAM="$1"
  RULE="false"

  # Remove all data for the program if the -all flag is provided
  if [[ "$2" == "-all" ]]; then
    RULE=""
  # If the second argument is an inscope rule, remove data matching the inscope rule
  elif [[ "$2" =~ ^(\*\.)?[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$ ]]; then
     # If the inscope rule has a leading *., remove the *. before using it
      if [[ "$2" =~ ^\*. ]]; then
          RULE="${2#*.}"
      else
          RULE="$2"
      fi

  else
    echo "Error $2 format is not supported"
    return 1
  fi
    # Remove data matching the inscope rule in URLs and domains
    echo "Removing inscope"
    bbrf scope in -p "$PROGRAM" | grep "$RULE"| bbrf inscope remove - -p "$PROGRAM"
    echo "Removing domains"
    bbrf domains -p "$PROGRAM" | grep "$RULE" | bbrf domain remove - -p "$PROGRAM"
    echo "Removing urls"
    bbrf urls -p "$PROGRAM" | grep "$RULE" | bbrf url remove -

}

#remove outscope from a program
removeOutScope()
{
    if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} program"
        echo "Example ${FUNCNAME[0]} IBM"
        return 1
    fi

    PROGRAM="$1"
    bbrf scope out -p "$PROGRAM"|bbrf outscope remove -
}

#clear all data of a program without removing it
# Examples
# removes all data from AT&T program
# > clearProgramData ATT  
clearProgramData()
{
    if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} program"
        echo "Example ${FUNCNAME[0]} IBM"
        return 1
    fi

    PROGRAM="$1"
    removeUrls $PROGRAM
    removeDomains $PROGRAM
    removeInScope $PROGRAM
    removeOutScope $PROGRAM
}

cleanDomainsPrograms()
{
IFS=$'\n'
store='/tmp'
threads=2000
URL="https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt"
wget -q $URL -O "$store/resolvers.txt"

for i in $(bbrf programs);do 
    echo "Cleaning domains in program $i"
    p="$i"
    oldDomains="$store/domains.$p.txt" 
    resolvedDomains="$store/domains.$p.resolved.txt"
    toRemoveDomains="$store/diff.domains.$p.txt"
    bbrf domains -p "$p" > "$oldDomains"
    dnsx -l "$oldDomains" -t $threads -silent -o "$resolvedDomains" -r "$store/resolvers.txt"
    diffFiles "$oldDomains" "$resolvedDomains" "$toRemoveDomains"
    num=$(wc -l "$toRemoveDomains"|getField 1)
    echo "Removing $num domains"
    cat "$toRemoveDomains"|bbrf domain remove -
    echo "----------------------------------------"
done

}
