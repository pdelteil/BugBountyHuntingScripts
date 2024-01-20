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
    modules=(httpx nuclei puredns-bruteforce shuffledns waybackurls amass subfinder)
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
            cat $log_path/*|grep $year|grep -v 'Unsolicited\|Skipped'|sort -k1
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
    #subfinder
     elif [[ $axiomModule = "subfinder" ]]; then
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

# find all stranded scan+* files and move them to a given folder 
# only if they are not already on the folder. 
# Examples
# moves all output files names scan+* to folder ~/result_scans
# > findAndMoveScans ~/result_scans
findAndMoveScans()
{
    # Print usage information if -h or --help flag is used or no arguments are provided
    if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ -z "$1" ]; then
        echo "Usage: ${FUNCNAME[0]} FOLDER"
        echo "Moves all files containing the word 'scan+' in their name to the specified FOLDER."
        return
    fi

    # Set internal field separator to newline character
    IFS=$'\n'

    # Set target folder to provided argument
    folder="$1"
    
    # Get path to locate database and its age
    dbpath=$(locate --statistics | head -n 1|awk '{print $2}')
    db_age=$(stat -c %Y $dbpath)
    curr_time=$(date +%s)
    age_diff=$(( curr_time - db_age ))
    age=$(( age_diff / 60 ))
    # Prompt user to update database if it is older than 2 hours
    read -p "Locate database is older than $age_diff seconds. Update database (this could take a while) (y/n)? " update_db
    if [[ "$update_db" == "y" ]]; then
        echo "Updating locate db"
        sudo updatedb
    fi

    # Get list of files containing "scan+" in their name and exclude the target folder
    files=$(locate scan+|grep -v "$folder")

    if [ -z "$files" ]; then
        echo "No scan+* files found"
        return 1

    else
        # Move each file to the target folder
        for file in $(echo "$files"); do 
            echo "Moving $file to $folder"
            mv -i "$file" "$folder"
        done
    fi
}
# input program name
# > nucleiScan program
# > nucleiScan all 
nucleiScan()
{
    # Maximum number of instances to spin up
    maxInstances=50

    # Check for help flag
    if [[ $# -eq 0 ]] || [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
        echo "Usage: ${FUNCNAME[0]} [program]"
        echo "Scans specified program or all programs if 'all' is provided as input using nuclei."
        echo " Options:"
        echo "  -h, --help Display this help message"
        return
    fi
    #TODO: remove excluded id, add them into config file
    # Set options for scan
    options="-stats -si 180 -ts -es info,unknown -eid expired-ssl,weak-cipher-suites,self-signed-ssl,missing-headers,mismatched-ssl"

    # Set program to scan
    program="$1"

    # Create a file with a unique name based on the current date and time
    date=$(date +%Y-%m-%d_%H-%M-%S)
    file="/tmp/$1_urls_$date.txt"

    # Get list of URLs for specified program or all programs
    if [[ $program == "all" ]]; then
        echo "Running bbrf urls --all --show-disabled this might take a while"
        bbrf urls --all --show-disabled > $file
    else
        bbrf urls -p "$program" > $file
    fi

    # Get number of instances currently in state running
    instances=$(axiom-ls|grep running)

    if [[ $instances -eq 0 ]]; then
      spinup="--spinup $maxInstances"
    else
      spinup=""
    fi

    echo "Running axiom-scan..."
    # Run scan and attaching to screen session 
    screen -S "axiom-scan-nuclei" axiom-scan $file -m nuclei $options $spinup

}
# set as selected instances all available (running state) ones
selectAllInstances()
{
    axiom-ls|grep running | getField 1|removeColor > ~/.axiom/selected.conf
    axiom-select
    instances=$(wc -l ~/.axiom/selected.conf| getField 1)
    echo "number of instances $instances"
}

#builds a list of GOOD DNS servers 
buildResolversList()
{
     # Check for help flag
    if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
        echo "Usage: ${FUNCNAME[0]}"
        echo " Options:"
        echo "  -h, --help Display this help message"
        return
    fi
    dnsvalidatorThreads=30
    maxInstances=50

    # Set options for scan
    options="-threads $dnsvalidatorThreads -o ~/resolvers.txt"
    # Get number of instances currently in state running
    instances=$(axiom-ls|grep running)

    if [[ $instances -eq 0 ]]; then
      spinup="--spinup $maxInstances"
    else
      spinup=""
    fi
    
    #getting list of potential name servers 
    wget https://public-dns.info/nameservers.txt -O /tmp/nameservers.txt
    #build a resolver list using dnsvalidator
    axiom-scan nameservers.txt -m dnsvalidator $options $spinup --rm-when-done
    #resolve domains [dnsx]

}

discoverContent()
{

# katana

# feroxbuster   
echo ok

}

bruteForceDNSRecords()
{

#puredns
#resolve again
   echo remove


}
reconScan()
{
    date=$(date +%Y-%m-%d_%H-%M-%S)
    local file="/tmp/domains.output.$date.txt"    
    subfinderThreads=20
    #getInscope 
    #TODO: check if call fails
    getProgramData all money inscope | tee $file
    
    #TODO: check if there is a fleet up -> param spinup 
    #run amass
    axiom-scan $file -m amass -wL ~/amass_config.ini -o ~/results/outputfile_amass_$date.txt
    #run subfinder
    # TODO: add config file
    axiom-scan $file -m subfinder -wL ~/.config/subfinder/provider-config.yaml -t $subfinderThreads -all -o ~/results/outputfile_subfinder_$date.txt
    #run assetfinder
    axiom-scan $file -m assetfinder --rm-when-done -o ~/results/outputfile_assetfinder_$date.txt
    #mergeOutput
    cat ~/results/outputfile_assetfinder_$date.txt ~/results/outputfile_subfinder_$date.txt \
        ~/results/outputfile_amass_$date.txt > ~/results_outputfile_merged_$date.txt

    #use dnsvalidator to generate list of DNS servers

    #addDomains in Chunks (screen?)

    #reportNewDomains
    
    #Probe for URLS
        #httpx / httprobe
        #addUrls in Chunks

        #reportNewUrls
    
    #TODO another function
        #nucleiScan 


    echo "Done! "
}

# resolve urls from domains using httpx and httprobe    
getAllUrls()
{
    #TESTING IN PROGRESS
    date=$(date +%Y-%m-%d_%H-%M-%S)
    local file="/tmp/domains.bbrf.$date.txt"
    local options="-rl 300 --threads 110 -sc -td -ct -lc -wc -rt -title -location -method -websocket -ip -cname -cdn -stats -si 180 --rm-when-done"
    #local axiom_options="-o outputfile.httpx.txt --rm-when-done"
    echo "Extracting domains from BBRF..."
    bbrf domains --all > "$file"
    echo "Running axiom-scan..."
    # Run scan and attaching to screen session axiom-scan $file -m httpx $options $axiom_options
    screen -S "axiom-scan-httpx" axiom-scan $file -m httpx $options #$axiom_options
    addInChunks outputfile.httpx.txt urls 2500 
}
