# shell script functions to be loaded on your bashrc file 

#Global variables
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
# creates a file with BBRF stats 
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
    for program in $(bbrf programs --show-disabled --show-empty-scope);
        do 
            echo "Getting stats of program $program"
            numUrls=$(bbrf urls -p "$program" | wc -l)
            numDomains=$(bbrf domains -p "$program" | wc -l)
            echo -e "$program, $numDomains,  $numUrls" >> $filename
    done
}

# displays all the disabled programs in BBRF
# DEPRECATED due to BBRF update
getDisabledPrograms()
{
    for program in $(bbrf programs --show-disabled 2>/dev/null);
        do 
            disabled=$(bbrf show "$program" 2>/dev/null| jq '.disabled')
            if [ "$disabled" == "true" ]
            then
                echo -e $program
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
    if [ -z "$1" ] | [ -z "$2" ] | [ -z "$3" ]
    then
      echo "Use ${FUNCNAME[0]} file1.txt file2.txt output.txt"
      return 1;
    fi
    comm -3 <(sort $1) <(sort $2) > $3
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
                echo "$scopeIn"|subfinder -t 60 -silent |dnsx -silent |tee --append "$tempFile-subfinder"
            else
                echo "$scopeIn"|subfinder -t 60 -silent |dnsx -silent|bbrf domain add - -s subfinder  --show-new;
            fi
            echo -ne "${RED} Running assetfinder ${ENDCOLOR}\n"

            if [ "$fileMode" = true ] ; then
                echo "$scopeIn"|assetfinder|dnsx -silent|tee --append "$tempFile-assetfinder"
            else
                echo "$scopeIn"|assetfinder|dnsx -silent| bbrf domain add - -s assetfinder --show-new;
            fi
            #chaos is included in httpx
            #echo -ne "${RED} Running chaos ${ENDCOLOR}\n"
            #if [ "$fileMode" = true ] ; then
            #    echo "$scopeIn"|chaos -silent -key $chaosKey |dnsx -silent| tee --append "$tempFile-chaos"
            #    echo -ne "${YELLOW} Removing duplicates from file ${ENDCOLOR}\n"
            #    cat "$tempFile-*" > "$file"
                #rm "$tempFile"
            #    echo "Done getDomains for "|notify -silent
            #else
            #    echo "$scopeIn"|chaos -silent -key $chaosKey |dnsx -silent|bbrf domain add - -s chaos --show-new;
            #fi
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
            echo "$doms"|httpx -silent -threads 100|bbrf url add - -s httpx --show-new
            echo -en "${RED} httprobe domains ${ENDCOLOR}\n"
            echo "$doms"|httprobe -c 50 -prefer-https|bbrf url add - -s httprobe --show-new
    fi
}
# Use this function if you need to add several programs from a site
# You need to add Name, Reward, URL, inscope and outscope
# input platform/site
# Example addPrograms intigriti
addPrograms()
{
    if [ -z "$1" ]
    then
      echo -ne "Use ${FUNCNAME[0]} site\nExample ${FUNCNAME[0]} h1\nExample ${FUNCNAME[0]} bugcrowd\n"
      return 1;
    fi
    unset IFS
    while true;
    do
        #reset
        # Read the user input
        site="$1"
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
        #recon means the scope is not bounded or clear
        echo -en "${YELLOW}Recon? ${ENDCOLOR} (1:false, 2:true) "
        read recon
        case $recon in 
            1)    val_recon="false";;
            2)    val_recon="true";;
        esac
        echo -en "${YELLOW}Android app? ${ENDCOLOR} (1:false[default:press Enter], 2:true) "
        read android
        case $android in 
            1 )    val_android="false";;
            2 )    val_android="true";;
            "")    val_android="false";;
        esac
        echo -en "${YELLOW}iOS app? ${ENDCOLOR} (1:false[default:press Enter], 2:true) "
        read iOS
        case $iOS in 
            1 )    val_iOS="false";;
            2 )    val_iOS="true";;
            "")    val_iOS="false";;
        esac
        echo -en "${YELLOW}Source code? ${ENDCOLOR} (1:false[default:press Enter], 2:true) "
        read source
        case $source in 
            1 )    val_source="false";;
            2 )    val_source="true";;
            "")    val_source="false";;
        esac
        
        result=$(bbrf new "$program" -t site:"$site" -t reward:"$val"  -t url:"$url" -t recon:"$val_recon" \
                            -t android:"$val_android" -t iOS:"$val_iOS" -t sourceCode:"$val_source")
        #echo $result
        if [[ $result == *"conflict"* ]] 
            then
            echo "Program conflict"
            bbrf use "$program"
        fi
        echo -en "${YELLOW} Add IN scope: ${ENDCOLOR}\n"
        read -r inscope_input
        #if empty skip
        if [ ! -z "$inscope_input" ]
            then
                bbrf inscope add $inscope_input -p "$program"
                echo -ne "${RED} inscope: \n"
                bbrf scope in -p "$program"
                echo -ne "${ENDCOLOR}\n"
                
        fi         
        echo -en "${YELLOW} Add OUT scope: ${ENDCOLOR}" 
        read -r outscope_input
        if [ ! -z "$outscope_input" ]
           then
               bbrf outscope add $outscope_input #-p "$program"
               echo -ne "${YELLOW}out Scope added${ENDCOLOR}\n"  
        fi
    echo -ne "${RED}Getting domains${ENDCOLOR}\n"; getDomains  
    echo -ne "${RED}Getting urls ${ENDCOLOR}\n"; getUrls  
    done
} 

# is faster to remove urls in chunks than directly 
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

# 1. ADD Domains IN CHUNKS from FILE containing domains 
# 2. Add URLs to program probing domains from FILE containing domains
addInCHUNKS()
{
 if [ -z "$1" ] || [ -z "$2" ]
    then
      echo "To add domains use ${FUNCNAME[0]} fileWithDomains domains source"
      echo "To add urls use ${FUNCNAME[0]} fileWithDomains urls"
      return 1
    fi
 if [ "$2" ==  "domains" ] || [ "$2" == "urls" ]
    then
        echo "" 
    else
        echo " use domains or urls "
        return 1
    fi
 source="$3"
 file="$1"
 size=$(cat "$file" |wc -l)
 echo "Size "$size
 chunk=1000
 echo "Chunk size "$chunk
 parts=$((size%chunk?size/chunk+1:size/chunk))
 echo "Chunks "$parts
 init=1
 end=$chunk
 for i in $(seq 1 $parts);
    do
        echo "Adding chunk $i"
        urls="${init},${end}p"; 
        if [ "$2" == "urls" ]
        then
            sed -n "$urls" "$file"|bbrf url add - -s httpx --show-new -p@INFER
        else
            sed -n "$urls" "$file"|bbrf domain add - -s "$source" --show-new -p@INFER
        fi
        init=$(( $init + $chunk ))
        end=$(( $end + $chunk ))
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
findProgram()
{
    INPUT=$(echo "$1"|sed 's/\/*$//g') #in case the add a trailing / 
    if [ -z "$INPUT" ]
    then
      echo "Use ${FUNCNAME[0]} URL or domain"
      return 1;
    fi
    program=$(bbrf show "$INPUT" |jq -r '.program')
    if [ ${#program} -gt 0 ] 
    then
        tags='.tags.site+", "+._id+", "+.tags.reward+", "+.tags.url+", disabled:"+(.disabled|tostring)+", recon:"+(.tags.recon|tostring)+", source code: "+(.tags.sourceCode|tostring)'
        bbrf show "$program" | jq "$tags" 
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
    for program in $(bbrf programs --show-disabled --show-empty-scope);
        do 
            #tags='tags.site'
            echo "$program " $(bbrf show "$program"|jq '.tags.site')
    done
    
}

#get all domains and try to find more subdomains using chaos project  
addDomainsAndUrls()
{
    IFS=$'\n'  
    echo  "Getting domains from subfinder"

    for prog in $(bbrf programs)
        do
         echo " $prog"
         bbrf scope in -p "$prog" \
                                | subfinder -t 60 -silent \
                                | dnsx -silent \
                                | bbrf domain add - -s subfinder --show-new -p "$prog" \
                                | grep -v DEBUG| notify -silent
        #urls
        bbrf urls -p "$prog" |httpx -silent -threads 120|bbrf url add - -s httpx --show-new -p "$prog" \
                             |grep -v DEBUG|notify -silent 
        done 
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
 fi
 if [ "true" == "$1" ]
    then
        echo "Setting BBRF debug mode on"
        sed -i 's/"debug": false/"debug": true/g' $configFile
 fi

} 
