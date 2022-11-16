#axiom helper
#Global variables
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

#AXIOM_PATH="/data"
AXIOM_PATH="$HOME/.axiom"
#show logs from axiom scans
# input param is the module used to scan
# 
showLogs()
{
    modules=(httpx nuclei puredns-bruteforce shuffledns waybackurls amass)
    if [[ -z "$1" ]]; then
        echo -e "\nUse ${FUNCNAME[0]} axiomModule -stats (optional, will show only number of output values)"
        echo -en "${YELLOW}Supported modules\n"
        for i in "${modules[@]}"; do
            echo -e "    $i"
        done
        return 1
    fi

    axiomModule=$1
    stats=$2
    error="is not running or there are no logs"
    #find latest folder of given axiomModule
    log_path=$(ls -td $AXIOM_PATH/tmp/$axiomModule* 2>/dev/null| head -n 1|sed 's/://g')
    log_path=$log_path/logs
    year=$(date +"%Y-")

    #amass
    if [[ $axiomModule = "amass" ]]; then

        if [[ ${#log_path} -gt 5 ]]; then
            cd $log_path
            if [[ "$stats" == "-stats" ]]; then
                running=$(wc -l ../status/completed/hosts|awk '{print $1}')
                total=$(ls |wc -l ) #* | awk '{print $1}')
                echo "Completed scans $running/$total"
                echo  "Output "
                wc -l * | grep total
            else
               tail -f *
            fi

            #cat $log_path/* #|grep $year #|grep -v Unsolicited
        else 
            echo "$axiomModule $error"
    fi
    #nuclei 
    elif [[ $axiomModule = "nuclei" ]]; then
        if [[ ${#log_path} -gt 5 ]]; then
            cd $log_path
            #nuclei especific grep rules 
            cat $log_path/*|grep $year|grep -v Unsolicited
        else 
            echo "$axiomModule $error"

    fi
    
    #shuffledns
    elif [[ $axiomModule = "shuffledns" ]]; then
        if [[ ${#log_path} -gt 5 ]]; then
            cd $log_path
            cat $log_path/*|grep -v 'INF\|WRN\|projectdiscovery'
        fi
    #elif end
    #puredns
    elif [[ $axiomModule = "puredns-bruteforce" ]]; then
        if [[ ${#log_path} -gt 5 ]]; then
           cd $log_path
           cat $log_path/*|grep ETA
        else 
            echo "$axiomModule $error"
        fi
    #elif end
    #httpx
    elif [[ $axiomModule = "httpx" ]]; then
        if [[ ${#log_path} -gt 5 ]]; then
            cd $log_path
            if [[ "$stats" == "-stats" ]]; then
                wc -l *
            else
               tail -f *
            fi
        else 
            echo "$axiomModule $error"
        fi
    #elif end
    #waybackurls 
    #in this case we don't want to see the actual output (too many lines) 
    # 1. number of finishes scans vs remaining 
    # 2. number of output lines 
    elif [[ $axiomModule = "waybackurls" ]]; then
        if [[ ${#log_path} -gt 5 ]]; then
            cd $log_path
            if [[ "$stats" == "-stats" ]]; then
                echo -n "Completed scans "
                wc -l ../status/completed/hosts|awk '{print $1}'
            else
               tail -f *
            fi
        else 
            echo "$axiomModule $error"
        fi
    #elif end 
    else 
        echo "module $axiomModule not supported"
    fi
}

#find all stranded scan+* files and move them to a given folder 
#only if they are not already on the folder. 
# Examples
# moves all output files names scan+* to folder ~/result_scans
# > findAndMoveScans ~/result_scans
findAndMoveScans()
{
    if [[ -z "$1" ]]; then
      echo "Use ${FUNCNAME[0]} outputFolder"
      return 1
    fi
    IFS=$'\n'
    #input 
    folder="$1"
    echo "Updating locate db (this could take a while)"
    #TODO check if db is old enough or ask the user if update is required
    sudo updatedb
    files=$(locate scan+|grep -v "$folder")
    for file in $(echo "$files"); do 
        echo "Moving $file to $folder"
        mv -i "$file" "$folder"
    done
}
# input program name
nucleiScan()
{

    if [[ -z "$1" ]]; then
      echo "Use ${FUNCNAME[0]} programName"
      return 1
    fi

    program="$1"
    file="/tmp/$1urls.tmp"
    #dump all program's urls
    bbrf urls -p "$program" > $file 
    axiom-scan $file -m nuclei -stats -si 180 -es info,unknown 

}
