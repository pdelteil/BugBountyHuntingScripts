#axiom helper

#show logs from running axiom scan
# input param is the module used to scan
showLogs()
{
 if [ -z "$1" ]
    then
      echo "Use ${FUNCNAME[0]} axiomModule"
      echo -e "Supported modules\n nuclei\n shuffledns\n puredns"
      return 1;
    fi

axiomModule=$1
#find latest folder of given axiomModule
log_path=$(ls -td ~/.axiom/tmp/$axiomModule* 2>/dev/null| head -n 1|sed 's/://g')
log_path=$log_path/logs

#TODO add more grep especific rules for other modules
#nuclei especific grep rules 
year=$(date +"%Y-")

#nuclei 
if [ $axiomModule = "nuclei" ]
    then
        cd $log_path
        cat $log_path/*|grep $year|grep -v Unsolicited
#shuffledns
elif [ $axiomModule = "shuffledns" ] 
    then
        cd $log_path
        cat $log_path/*|grep -v 'INF\|WRN\|projectdiscovery'|grep '\.'

#puredns
elif [ $axiomModule = "puredns" ] 
    then
        cd $log_path
        cat $log_path/*|grep -v 'INF\|WRN\|projectdiscovery'|grep '\.'

else 
    echo "module $axiomModule not supported"

fi

}

#find all stranded scan+* files and move them to a given folder 
#only if they are not already on the folder. 
findAndMoveScans()
{
    if [ -z "$1" ]
    then
      echo "Use ${FUNCNAME[0]} outputFolder"
      return 1;
    fi
    IFS=$'\n'
    #input 
    folder="$1"
    echo "Updating locate db (could take a while)"
    #TODO check if db is old enough or ask the user if update is required
    sudo updatedb
    files=$(locate scan+|grep -v "$folder")
    for file in $(echo "$files");
        do 
            echo "Moving $file to $folder"
            mv -i "$file" "$folder"
    done
}

