#axiom helper

#show logs from running axiom scan
# input param is the module used to scan
showLogs()
{
 if [ -z "$1" ]
    then
      echo "Use ${FUNCNAME[0]} axiomModule"
      return 1;
    fi

axiomModule=$1
#find latest folder of given axiomModule
log_path=$(ls -t ~/.axiom/tmp/$axiomModule* | head -n 1|sed 's/://g')
log_path=$log_path/logs
cd $log_path
#TODO add more grep especific rules for other modules
#nuclei especific grep rules 
if [ $axiomModule = "nuclei" ] 
    then
        cat $log_path/*|grep "2021-"|grep -v Unsolicited
    else    
        cat $log_path/*
fi
}
