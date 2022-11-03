# shell script functions to be loaded on your bashrc file

#Global variables
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

#update program data after outscope change 
#When you add a new outscope rule(s) you'd like that the program data gets updated
#this means removing domains and urls that now are out of scope
#This is something I need to do when I'm invited to a BBP that also has a VDP
updateProgram()
{

  if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} program rule"
        return 1
    fi

    #this should work for adding/removing a inscope rule 
    program="$1"
    rule="$2"

    #check if the program has that rule 
    check=$(bbrf show "$program" | grep -i "$rule")

    #careful when the remove url is a subdomain of a wildcard rule

    if [[ ${#check} -gt 0 ]]; then
        echo "rule in program"
        #removing rule from program
        #stats before removing
        inscopeRules=$(bbrf show "$program"|jq '.inscope'|grep '"'|wc -l)
        domains=$(bbrf domains -p "$program"|wc -l)
        urls=$(bbrf urls -p "$program"|wc -l)
        echo "Stats before update inscope rules: $inscopeRules, domains: $domains,  urls: $urls"

        bbrf inscope remove "$2" -p "$program"
        #removing wildcard
        rule=$(echo $rule|sed 's/*\.//g' )
        #removing domains
        bbrf domains -p "$program"|grep -i "$rule" | bbrf domain remove - -p "$program"
        #remove urls
        bbrf urls -p "$program"|grep -i "$rule" |bbrf url remove -  #we don t need program here
    
    else
        echo "rule not in program $program"
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
    #headers
    headers="Program; Site; Program url; disabled; reward; author; notes; added Date; #domains; #urls; #IPS" 
    echo -e $headers >> $filename
    echo "Getting stats of programs $param"
    
    allPrograms=$(bbrf programs $param --show-empty-scope)
    numberPrograms=$(echo "$allPrograms"|wc -l)
    #counter
    i=1
    for program in $(echo "$allPrograms"); do 
        echo -en "${YELLOW}($i/$numberPrograms)${ENDCOLOR} $program\n"
        #fields/columns
        description=$(bbrf show "$program")
        site=$(echo "$description" |jq -r '.tags.site')
        reward=$(echo "$description" |jq -r '.tags.reward')
        programUrl=$(echo "$description" |jq -r '.tags.url')
        disabled=$(echo "$description" |jq -r '.disabled')
        author=$(echo "$description" |jq -r '.tags.author')
        notes=$(echo "$description" |jq -r '.tags.notes') 
        addedDate=$(echo "$description" |jq -r '.tags.addedDate')
        #metrics 
        numUrls=$(bbrf urls -p "$program"|wc -l)
        numDomains=$(bbrf domains -p "$program"|wc -l)
        #numIPs=$(bbrf ips -p "$program"|wc -l)
        values="$program; $site; $programUrl; $disabled; $reward; $author; $notes; $addedDate; $numDomains; $numUrls; $numIPs"
        echo -e $values >> $filename
        i=$(( $i + 1))
    done
}


# This function it's an interactive program to add new bbh programs 
# it requires dnsx, subfinder, gau, waybackurls, httprobe and assetfinder.
# dnsx will get rid of dead subdomains
# optional parameter is a file to output the data 
# The objetive is to get subdomains using different tools and adding the results to BBRF 
# The target program is the BBRF active program
# TODO: add flag -p to run getDomains to an especific program
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
            params="-p $2"
            echo "$params"
        else
            echo "add Program name!"
            echo "> getDomains -p program "
            return -1
        fi
    fi

    IFS=$'\n'
    scopeIn=$(bbrf scope in $params)
    echo "$scopeIn"|bbrf domain add - $params --show-new
    wild=$(bbrf scope in --wildcard $params| grep -v DEBUG)
    # when there's no wildcard we don't need the next steps
    if [[ ${#wild} -gt 0 ]]; then
        echo "$wild"|bbrf inscope add - $params
        echo "$wild"|bbrf domain add - $params --show-new

        echo -ne "${RED} Running amass ${ENDCOLOR}\n"
        if [[ "$fileMode" = true ]] ; then
            for scope in $(echo "$wild"); do                
                echo -ne "${YELLOW}  Querying $domain ${ENDCOLOR}\n"
                amass enum -d $domain -config ~/amass_config.ini -passive 2>/dev/null | dnsx -t $dnsxThreads -silent |tee --append "$tempFile-amass.txt"
            done
            else
                for domain in $(echo "$wild"); do
                    echo -ne "${YELLOW}  Querying $domain ${ENDCOLOR}\n"
                    amass enum -d $domain -config ~/amass_config.ini -passive 2>/dev/null | dnsx -t $dnsxThreads -silent | bbrf domain add - -s amass $params --show-new
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
# it requires httpx and httprobe
getUrls()
{
    threads=150
    doms=$(bbrf domains|grep -v DEBUG|tr ' ' '\n')
    if [[ ${#doms} -gt 0 ]]; then
        echo -en "${RED} httpx domains ${ENDCOLOR}\n"
        echo "$doms"|httpx -silent -threads $threads|bbrf url add - -s httpx --show-new
        echo -en "${RED} httprobe domains ${ENDCOLOR}\n"
        echo "$doms"|httprobe -c $threads --prefer-https|bbrf url add - -s httprobe --show-new
    fi
}
# Use this function if you need to add several programs from a site
# You need to add Name, Reward, URL, inscope and outscope
# input platform/site
# Example addPrograms intigriti hunter
addPrograms()
{
    if [[ -z "$1" ]] || [ -z "$2" ]]; then
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
        echo -en "${YELLOW}Notes/Comments? ${ENDCOLOR} (press enter if empty)"
        read notes

        result=$(bbrf new "$program" -t site:"$site" -t reward:"$val"  -t url:"$url" -t recon:"$val_recon" \
                 -t android:"$val_android" -t iOS:"$val_iOS" -t sourceCode:"$val_source" -t addedDate:"$addedDate" \
                 -t author:"$author" -t notes:"$notes" -t api:"$val_api" -t api_endpoints:"$api_endpoints" -t public:"$val_public")
        #echo $result
        if [[ $result == *"conflict"* ]]; then
            echo "Program already on BBRF!"
            bbrf show "$proWgram"|jq
            return -1
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
        if [[ ${#inscope_input} -gt 0 ]]; then
            echo -ne "${RED}Getting domains${ENDCOLOR}\n"
            getDomains  
            echo -ne "${RED}Getting urls ${ENDCOLOR}\n"
            getUrls  
            #getIPs
            #scanPorts
            #run nuclei
            numUrls=$(bbrf urls|wc -l) 
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
                bbrf urls | nuclei -t ~/nuclei-templates -es info,unknown -stats -si 180 -itags fuzz,dos
            else
                return 1; 
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
        echo -ne "{$YELLOW}Adding chunk $i/$parts{$ENDCOLOR}"
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
checkProgram()
{
    if [[ -z "$1" ]];
    then
      echo "Use ${FUNCNAME[0]} text"
      return 1
    fi
    text="$1"
    output=$(bbrf programs --show-disabled --show-empty-scope | grep -i "$text")
    if [[ ${#output} -gt 0 ]]; then
        echo -ne "${YELLOW}Programs found:\n$output ${ENDCOLOR} \n\n"
    else    
        echo -ne "${RED}No program found! ${ENDCOLOR}\n\n"
    fi
    #TODO: call wshowProgram from here, showing numeric options
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
    program=$(echo "$show" |jq -r '.program')
    #echo "$program"
    #case input is an IP
    if [[ $INPUT =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        domains=$(echo $show |jq -r '.domains'|grep "\."|tr -d '"')
        echo -en "\n${YELLOW} Domains: $domains${ENDCOLOR}\n"
        show=$(bbrf show "$program")
        #return 1
    fi

    if [[ ${#program} -gt 0 ]]; then
        #This tags are specific for my way of storing data
        #If you use addPrograms to inpput your programs this will work just fine
        site=".tags.site"
        author=".tags.author"
        reward=".tags.reward"
        url=".tags.url"
        AddedDate=".tags.addedDate"
        disabled="(.disabled|tostring)"
        recon="(.tags.recon|tostring)"
        source="(.tags.sourceCode|tostring)"
        notes=".tags.notes"
        api=".tags.api"
        public=".tags.public"
        gov=".tags.gov"
        #this part is hard to update -> need to find a way to simplify it
        tags='" Site: "+'"$site"' +", Name: "+._id+", Author: "+'"$author"'+", Reward: "+'"$reward"'+", Url: "+'"$url"'+", disabled: "+'"$disabled"'+", Added Date: "+'"$AddedDate"'+", recon: "+'"$recon"' +", source code: "+'"$source"' + ", Notes: "+'"$notes"'+ ", api: "+'"$api"'+", public: "+'"$public"'+", gov: "+'"$gov"
        output=$(bbrf show "$program" | jq "$tags" |tr -d '"'| sed 's/,/\n/g')
        echo -ne "\n$output\n\n"
        
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
        #echo $program ", "$key
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
# displays details a given program
showProgram()
{
    if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} programName -stats [optional, displays number of urls and domains]"
        return 1
    fi
    program="$1"
    output=$(bbrf show "$program"|jq)

    if [[ ${#output} -gt 0 ]]; then
        echo "$output" 
    else    
        echo -ne "${RED}$program not found! ${ENDCOLOR}\n\n"
        return 1
        
    fi
    
    flag="$2" 
    if [[ -z "$flag" ]]; then    
        return 1
    fi
   
    if [[ "$flag" == "-stats" ]]; then
        domains=$(bbrf domains -p "$program"|wc -l)
        urls=$(bbrf urls -p "$program"|wc -l) 
        echo -en "${YELLOW}#domains: "$domains "\n"
        echo -en "#urls: "$urls"${ENDCOLOR}\n"
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

    data=("$1")

    if [[ "$1" == "inscope" ]]; then
        #will output only inscope with a wildcard, ie *.domain.com
        data=("scope" "in" "--wildcard")    
    fi
    if [[ "$1" == "outscope" ]]; then
        data=("scope" "out")
    fi
    allPrograms=$(bbrf programs $param)

    IFS=$'\n'
    for program in $(echo "$allPrograms"); do
        description=$(bbrf show "$program")
        gov=$(echo "$description"  |jq -r '.tags.gov')
        if [[ "$gov" != "true" ]]; then
            bbrf ${data[@]} -p "$program"
        fi   
    done
}

#Get all urls from programs with a specific tag value
# Examples
# get all urls from Intigriti programs
# > getUrlsWithProgramTag intigriti  

# get all urls from bugcrowd programs
# > getUrlsWithProgramTag bugcrowd

getUrlsWithProgramTag()
{   
    if [[ -z "$1" ]] | [ -z "$2" ]]; then
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
removeInScope()
{
    if [[ -z "$1" ]];   then
        echo "Use ${FUNCNAME[0]} program"
        echo "Example ${FUNCNAME[0]} IBM"
        return 1
    fi

    PROGRAM="$1"
    bbrf scope in -p "$PROGRAM"|bbrf inscope remove -
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
