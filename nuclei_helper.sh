#nuclei helper

# function to manually test results from nuclei
# example of use 
# testNucleiTemplate open-redirect http://www.sample.com
# TODO add flag to debug optional
testNucleiTemplate()
{
 if [ -z "$1" ]
    then
      echo "Use ${FUNCNAME[0]} nuclei-template-id URL"
      return 1;
    fi

 templateID=$1
 URL=$2
 pathToTemplate=$(locate $templateID|grep yaml|head -n 1) 
 echo "nuclei -debug -t $pathToTemplate -u $URL -itags fuzz,dos"
 nuclei -debug -t $pathToTemplate -u $URL
}

#examples 
#search template by author
#searchTemplateByTag author philippedelteil 
#searchTemplateByTag severity medium
#TODO: use several tagvalues
searchTemplateByTag()
{
    if [ -z "$1" ] | [ -z "$2" ]
    then
      echo "Use ${FUNCNAME[0]} tagName tagValue"
      return 1;
    fi
    configFile="$HOME/.config/nuclei/.templates-config.json"
    property="nuclei-templates-directory"
    folder=$(cat $configFile| jq | grep $property|awk '{print $2}'|tr -d '"'|tr -d ',')

    tag="$1"
    value="$2"
    condition="$tag.*$value"
    grep -Ri "$condition" --include="*.yaml" $folder
}

#Use runScanTemplateVersion v8.5.8 urls.txt
runScanTemplateVersion()
{
    if [ -z "$1" ] | [ -z "$2" ]
    then
      echo "Use ${FUNCNAME[0]} version urls.txt"
      return 1;
    fi
    #git repo
    gitURL="https://github.com/projectdiscovery/nuclei-templates.git"
    branch="$1"
    file="$2"
    folder="/tmp/nuclei-templates-$branch"

    if [ -d "$folder" ] 
    then
        echo "Directory $folder exists. Skipping git clone" 
    else
        git clone --depth=1 --branch $branch $gitURL $folder
    fi

    nuclei -update-directory $folder -no-update-templates -l $file
}
