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

  if [ -z "$1" ]
    then
        echo "Use ${FUNCNAME[0]} program rule"
        return 1;
    fi

    #this should work for adding/removing a inscope rule 
    program="$1"
    rule="$2"

    #check if the program has that rule 
    check=$(bbrf show "$program" | grep -i "$rule")


    #careful when the remove url is a subdomain of a wildcard rule

    if [[ ${#check} -gt 0 ]]
    then
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
# getData only from disabled programs 
# Use getOnlyDisabledPrograms urls/domains condition (optional)
# ex 1 getting all urls from disabled programs
#  getOnlyDisabledPrograms urls 
# ex 2 getting all domains from disabled programs with condition (from BugCrowd)
#  getOnlyDisabledPrograms urls where site is bugcrowd
getOnlyDisabledPrograms()
{
    INPUT="$1" 
    COND="$2"
    if [ -z "$INPUT" ] 
    then
        echo "Use ${FUNCNAME[0]} urls/domains"
        return 1;
    fi
    IFS=$'\n'
    if [[  "$INPUT" != "urls"  &&  "$INPUT" != "domains" ]]
    then
        echo "Use ${FUNCNAME[0]} urls/domains"
        return 1;
    fi
    if [[  "$INPUT" == "urls" ]] | [[  "$INPUT" == "domains" ]]
    then
        all=$(bbrf programs --show-disabled $COND)
        enabled=$(bbrf programs $COND)
        # difference between all and enabled programs = disabled programs
        listr=$(comm -3 <(echo "$enabled"|sort) <(echo "$all"|sort)|tr -d '\t')
        echo "${#listr}"
    fi
    if [[  "$INPUT" == "urls" ]] 
    then
        for program in $(echo "$listr");
        do 
            bbrf urls -p "$program"
        done

    fi
    if [[  "$INPUT" == "domains" ]] 
    then
        for program in $(echo "$listr");
        do 
            bbrf domains -p "$program"
        done
    fi

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
#get inscope of all programs
getInScope()
{
    if [ -z "$1" ] || [[ "$1" == "-h"* ]] 
    then
       echo "Use ${FUNCNAME[0]} outputfile.txt"
       echo "Use ${FUNCNAME[0]} -disabled outputfile.txt (to include disabled programs)"
       return 1;
    fi
    outputFile="$1"
    IFS=$'\n' 
    if [[ "$1" == "-disabled" ]]
        then
            outputFile="$2"
            command=$(bbrf programs --show-disabled)
            echo -ne "${RED} Getting inscope of enabled and disabled programs ${ENDCOLOR}\n"
        else
            command=$(bbrf programs)
            echo -ne "${RED} Getting inscope of only enabled programs ${ENDCOLOR}\n"
    fi
     for program in $command;
        do 
            echo "$program" 
            bbrf scope in -p "$program" >> $outputFile
        done
}
# creates a file with BBRF stats in CSV format
# The output is in the form  program1, #domains, #urls
# Input parameter: filename
getStats()
{   
     if [ -z "$1" ]
      then
       echo "Use ${FUNCNAME[0]} outputfile.txt"
       return 1;
    fi

    IFS=$'\n'
    filename=$1
    #headers
    headers="Program, Site, disabled, reward, author, notes, #domains, #urls, #IPS" 
    echo -e $headers >> $filename
    echo "Getting stats of programs"
    
    allPrograms=$(bbrf programs --show-disabled --show-empty-scope)
    numberPrograms=$(echo "$allPrograms"|wc -l)
    #counter
    i=1
    for program in $(echo "$allPrograms");
        do 
            echo -en "${YELLOW}($i/$numberPrograms)${ENDCOLOR} $program\n"
            #fields/columns
            description=$(bbrf show "$program")
            site=$(echo "$description"    |jq -r '.tags.site')
            reward=$(echo "$description"  |jq -r '.tags.reward')
            disabled=$(echo "$description"|jq -r '.disabled')
            author=$(echo "$description"|jq -r '.tags.author')
            notes=$(echo "$description" |jq -r '.tags.notes') 
            addedDate=$(echo "$description" |jq -r '.tags.addedDate')
            numUrls=$(bbrf urls -p "$program"|wc -l)
            numDomains=$(bbrf domains -p "$program"|wc -l)
            numIPs=$(bbrf ips -p "$program"|wc -l)
            values="$program, $site, $disabled, $reward, $author, $notes, $addedDate, $numDomains, $numUrls, $numIPs"
            echo -e $values >> $filename
            i=$(( $i + 1))
        done
}


# This function is used when adding a new program 
# it requires dnsx, subfinder and assetfinder
# dnsx will get rid of dead subdomains
# optional parameter is a file to output the data 
getDomains()
{
    #no params
    file="$1"
    
    if [ -z "$file" ]
    then
        echo -ne "${YELLOW} Running bbrf mode ${ENDCOLOR}\n"
    else
        echo -ne "${YELLOW} Running filemode ${ENDCOLOR}\n"
        fileMode=true
        tempFile="/tmp/$file.temp"
    fi

    IFS=$'\n'
    wild=$(bbrf scope in --wildcard|grep -v DEBUG)
    echo "$wild"|bbrf inscope add -
    echo "$wild"|bbrf domain add - --show-new
    scopeIn=$(bbrf scope in)
    echo "$scopeIn"|bbrf domain add - --show-new
    # when theres no wildcard we dont need the next steps
    if [ ${#wild} -gt 0 ]
        then
            echo -ne "${RED} Running subfinder ${ENDCOLOR}\n"
            if [ "$fileMode" = true ] ; then
                echo "$scopeIn"|subfinder -t 100 -silent |dnsx -t 200 -silent |tee --append "$tempFile-subfinder"
            else
                echo "$scopeIn"|subfinder -t 100 -silent |dnsx -t 200 -silent|bbrf domain add - -s subfinder  --show-new;
            fi
            echo -ne "${RED} Running assetfinder ${ENDCOLOR}\n"

            if [ "$fileMode" = true ] ; then
                echo "$scopeIn"|assetfinder|dnsx -t 200 -silent|tee --append "$tempFile-assetfinder"
            else
                echo "$scopeIn"|assetfinder|dnsx -t 200 -silent|bbrf domain add - -s assetfinder --show-new;
            fi
   fi
}

# This function is used when adding a new program and after the getDomains function
# it requires httpx and httprobe
getUrls()
{
    doms=$(bbrf domains|grep -v DEBUG|tr ' ' '\n')
    if [ ${#doms} -gt 0 ]
        then
            echo -en "${RED} httpx domains ${ENDCOLOR}\n"
            echo "$doms"|httpx -silent -threads 150|bbrf url add - -s httpx --show-new
            echo -en "${RED} httprobe domains ${ENDCOLOR}\n"
            echo "$doms"|httprobe -c 150 --prefer-https|bbrf url add - -s httprobe --show-new
    fi
}
# Use this function if you need to add several programs from a site
# You need to add Name, Reward, URL, inscope and outscope
# input platform/site
# Example addPrograms intigriti hunter
addPrograms()
{
    if [ -z "$1" ] || [ -z "$2" ]
    then
      echo -ne "Use ${FUNCNAME[0]} site author\nExample ${FUNCNAME[0]} h1 hunter\nExample ${FUNCNAME[0]} bugcrowd hunter\n"
      return 1;
    fi
    unset IFS
    while true;
    do
        # Read the user input
        site="$1"
        author="$2"
        addedDate=$(date +%D-%H:%M)
        echo -en "${YELLOW}Program name: ${ENDCOLOR}"
        read program
        program=$(echo $program|sed 's/^ *//;s/ *$//')
        echo -en "${YELLOW}Reward? (1:money[default:press Enter], 2:points, 3:thanks) ${ENDCOLOR} "
        read reward
        case $reward in
            1 )    val="money";;
            2 )    val="points";;
            3 )    val="thanks";;
            "")    val="money";;
        esac
        echo -en "${YELLOW}Url? ${ENDCOLOR} "
        # TODO create tentative url combining site + program name
        read url
        #recon true means the scope is not bounded or clear
        # So you could spend more time/resources doing more specific recon
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
             "")    val_android="false";;
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
        echo -en "${YELLOW}Notes/Comments? ${ENDCOLOR} (press enter if empty) "
        read notes
        
        result=$(bbrf new "$program" -t site:"$site" -t reward:"$val"  -t url:"$url" -t recon:"$val_recon" \
                 -t android:"$val_android" -t iOS:"$val_iOS" -t sourceCode:"$val_source" -t addedDate:"$addedDate" -t author:"$author" -t notes:"$notes")
        #echo $result
        if [[ $result == *"conflict"* ]] 
            then
            echo "Program already on BBRF!"
            bbrf show "$program"|jq
            return -1
        fi
        echo -en "${YELLOW} Add IN scope: ${ENDCOLOR}\n"
        read -r inscope_input
        #if empty skip
        if [ ! -z "$inscope_input" ]
            then
                bbrf inscope add $inscope_input -p "$program"
                echo -ne "${RED} inscope: \n"
                #just to check everything went well
                bbrf scope in -p "$program"
                echo -ne "${ENDCOLOR}\n"
                
        fi         
        echo -en "${YELLOW} Add OUT scope: ${ENDCOLOR}\n" 
        read -r outscope_input
        #if empty skip
        if [ ! -z "$outscope_input" ]
           then
               bbrf outscope add $outscope_input -p "$program"
               echo -ne "${RED} outscope: \n"
               #just to check everything went well
               bbrf scope out -p "$program"
               echo -ne "${ENDCOLOR}\n"  
        fi
    echo -ne "${RED}Getting domains${ENDCOLOR}\n"; getDomains  
    echo -ne "${RED}Getting urls ${ENDCOLOR}\n"; getUrls  
    done
} 

# It is faster to remove urls in chunks than directly 
# works for the current active program
# in the case of URLs and IP the program is not mandatory, it will delete everything in the input file
removeInChunks()
{
    if [ -z "$1" ] || [ -z "$2" ]
    then
      echo "To remove domains use ${FUNCNAME[0]} fileWithDomains domains chunckSize (optional:default 1000)"
      echo "To remove urls use ${FUNCNAME[0]} fileWithUrls urls chunkSize (optional:default 1000)"
      echo "To remove ips use ${FUNCNAME[0]} fileWithIPs ips chunkSize (optional:default 1000)"
      return 1
    fi
    
    #input vars
    file="$1"
    type="$2"
    chunkSize="$3"

    if [ "$type" ==  "domains" ] || [ "$type" == "urls" ]  || [ "$type" == "ips" ]
    then
        echo "" 
    else
        echo " use domains, ips or urls "
        return 1
    fi

    size=$(cat "$file"|wc -l); 
    echo "Size "$size
    #default value for chunk size
    if [ -z "$chunkSize" ]
    then
        chunkSize=1000
    fi
    parts=$((size%chunkSize?size/chunkSize+1:size/chunkSize))

    echo "Chunk size "$chunkSize
    echo "Chunks "$parts
    init=1
    end=$chunkSize

    for i in $(seq 1 $parts);
    do
        echo "Removing chunk $i/$parts"
        element="${init},${end}p"; 

        if [ "$type" == "urls" ]
        then
            sed -n "$element" "$file"|bbrf url remove - 
        elif [ "$type" == "domains" ]
        then
           sed -n "$element" "$file"|bbrf domain remove - 
        elif [ "$type" == "ips" ]
        then
           sed -n "$element" "$file"|bbrf ip remove -
        fi
        init=$(( $init + $chunkSize ))
        end=$(( $end + $chunkSize ))
    done
}

# 1. ADD Domains IN CHUNKS from FILE containing domains 
# 2. Add URLs to program probing domains from FILE containing domains
# the chunk size depends on your bbrf (couchdb) server capacity 
addInChunks()
{
    if [ -z "$1" ] || [ -z "$2" ]
    then
      echo -ne "To add domains use ${YELLOW}${FUNCNAME[0]} fileWithDomains domains chunckSize (optional:default 1000) source (optional)${ENDCOLOR}\n"
      echo -ne "To add urls use ${YELLOW}${FUNCNAME[0]} fileWithUrls urls chunkSize (optional:default 1000) source (optional)${ENDCOLOR}\n"
      return 1
    fi
    #input vars
    file="$1"
    type="$2"
    chunkSize="$3"
    source="$4"

    if [ "$type" ==  "domains" ] || [ "$type" == "urls" ]
    then
        echo "" 
    else
        echo " use domains or urls "
        return 1
    fi

    size=$(cat "$file" |wc -l)
    echo "Size "$size
    #default value for chunk size
    if [ -z "$chunkSize" ]
    then
        chunkSize=1000
    fi
    echo "Chunk size "$chunkSize
    parts=$((size%chunkSize?size/chunkSize+1:size/chunkSize))
    echo "Chunks "$parts
    init=1
    end=$chunkSize

     if [ -z "$source" ]
     then
        source=""
     fi

     for i in $(seq 1 $parts);
     do
        echo "Adding chunk $i/$parts"
        elements="${init},${end}p"; 

        if [ "$type" == "urls" ]
        then
            sed -n "$elements" "$file"|bbrf url add - -s "$source" --show-new -p@INFER
        else
            sed -n "$elements" "$file"|dnsx -silent|bbrf domain add - -s "$source" --show-new -p@INFER
        fi
        init=$(( $init + $chunkSize ))
        end=$(( $end + $chunkSize ))
    done
} 
#resolve domains IN CHUNKS
resolveDomainsInChunks()
{
 if [ -z "$1" ] || [ -z "$2" ]
    then
      echo "Use ${FUNCNAME[0]} fileUnresolvedDomains"
      return 1;
    fi

 file=$1
 size=$(cat $file |wc -l); 
 echo $size
 chunk=100
 parts=$((size%chunk?size/chunk+1:size/chunk))
 echo $parts
 init=1
 end=$chunk
 for i in $(seq 1 $parts) ; 
    do
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
checkProgram()
{
    if [ -z "$1" ]
    then
      echo "Use ${FUNCNAME[0]} text"
      return 1;
    fi
    text="$1"
    output=$(bbrf programs --show-disabled --show-empty-scope | grep -i "$text")
    if [ ${#output} -gt 0 ] 
    then
        echo -ne "${YELLOW}Programs found:\n$output ${ENDCOLOR} \n\n"
    else    
        echo -ne "${RED}No program found! ${ENDCOLOR}\n\n"
    fi
}

#finds the program name from a domain, URL or IP Adress. 
#Useful when you find a bug but you don't know where to report it (what programs it belongs to). 
findProgram()
{
    INPUT=$(echo "$1"|sed -e 's|^[^/]*//||' -e 's|/.*$||') #in case the input has a trailing / 
    if [ -z "$INPUT" ]
    then
      echo "Use ${FUNCNAME[0]} URL, domain or IP Address"
      return 1;
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

    if [ ${#program} -gt 0 ] 
    then
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
        #detect if input is an IP address 
        #this part is hard -> need to find a way to simplify it
        tags='" Site: "+'"$site"' +", Name: "+._id+", Author: "+'"$author"'+", Reward: "+'"$reward"'+", Url: "+'"$url"'+", disabled: "+'"$disabled"'+", Added Date: "+'"$AddedDate"'+", recon: "+'"$recon"' +", source code: "+'"$source"' + ", Notes: "+'"$notes"
        #echo "show: $show"
        output=$(bbrf show "$program" | jq "$tags" |tr -d '"'| sed 's/,/\n/g')
        echo -ne "\n$output\n\n"
        
    else
        echo -ne "${RED}No program found!${ENDCOLOR}\n\n"
    fi
}

# Lists all key values of a given tag 
# TODO list all tags and select one 
listTagValues()
{   
    if [ -z "$1" ]
    then
        echo "Use ${FUNCNAME[0]} TagName"
        return 1;
    fi

    tag="$1"
    IFS=$'\n'
    for program in $(bbrf programs --show-disabled);
        do 
            key=$(bbrf show "$program"|jq '.tags.site')
            #echo $program ", "$key
            keys+=("$key") 
    done
    #show unique key values
    echo "${keys[@]}" | tr ' ' '\n' | sort -u
    
}

# sets debug mode on or off
debugMode()
{
 configFile="$HOME/.bbrf/config.json"

 #detect if debug mode is not set in config file 
 debug=$(grep '"debug"' $configFile)
 
 if [ ${#debug} == 0 ] #debug word not found in config file
    then
        sed -i 's/}/,"debug": true}/g' $configFile
 fi
 if [ -z "$1" ]
    then
        echo "Use ${FUNCNAME[0]} false/true"
        return 1;
 fi
 if [ "false" == "$1" ]
    then
        echo "Setting BBRF debug mode off"
        sed -i 's/"debug": true/"debug": false/g' $configFile
 elif [ "true" == "$1" ]
    then
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

 program=$(cat $configFile|jq|grep "program"|awk -F":" '{print $2}'|tr -d ","|tr -d '"'|sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
 
 echo "$program" 

}
# displays details a given program
showProgram()
{
    if [ -z "$1" ] 
    then
        echo "Use ${FUNCNAME[0]} programName -stats [optional, displays number of urls and domains]"
        return 1;
    fi
    program="$1"
    output=$(bbrf show "$program"|jq)

    if [ ${#output} -gt 0 ] 
    then
        echo "$output" 
    else    
        echo -ne "${RED}$program not found! ${ENDCOLOR}\n\n"
        return 1
        
    fi
    
    flag="$2" 
    if [ -z "$flag" ]
    then    
        return 1
    fi
   
    if [ "$flag" == "-stats" ]
    then
        domains=$(bbrf domains -p "$program"|wc -l)
        urls=$(bbrf urls -p "$program"|wc -l) 
        echo "#domains "$domains
        echo "#urls "$urls
         
    else
        echo "Use ${FUNCNAME[0]} programName -stats [optional, displays number of urls and domains] "
        return 1
    fi
}

# adds IPs from a CIDR to a program
#example addIPsFromCIDR 128.177.123.72/29 program
addIPsFromCIDR()
{
    if [ -z "$1" ] | [ -z "$2" ]
    then
        echo "Use ${FUNCNAME[0]} 128.177.123.72/29 program"
        return 1;
    fi

    CIDR="$1"
    program="$2"
    #params are just to speed up ping
    fping -t 5 -r 1  -b 1 -g $CIDR 2> /dev/null|awk '{print $1}'|bbrf ip add - -p $program --show-new
}
#this function is especific for my implementation. 
#the output if all urls but urls from programs with tag gov
getBugBountyUrls()
{
    allPrograms=$(bbrf programs --show-disabled)
    IFS=$'\n'
    for program in $(echo "$allPrograms");
        do
            description=$(bbrf show "$program")
            gob=$(echo "$description"  |jq -r '.tags.gov')
            if [ "$gob" == "true" ]
            then
                echo ""
            else
                bbrf urls -p "$program"
            fi   
        done
}
