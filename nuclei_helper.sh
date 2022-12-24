#nuclei helper

# function to manually test results from nuclei
# example of use 
# testNucleiTemplate open-redirect http://www.sample.com -debug
testNucleiTemplate() 
{
  if [[ -z "$1" ]]; then
    echo "Use ${FUNCNAME[0]} nuclei-template-id URL [-debug]"
    echo "This function runs the nuclei tool with the specified template and URL, and with the optional -debug flag."
    return 1
  fi

  templateID="$1"
  URL="$2"
  debugFlag=""
  if [[ "$3" == "-debug" ]]; then
    debugFlag="-debug"
  fi

  pathToTemplate=$(locate "$templateID" | grep yaml | head -n 1) 
  echo "nuclei $debugFlag -t $pathToTemplate -u $URL -itags fuzz,dos"
  nuclei $debugFlag -t "$pathToTemplate" -u "$URL" -itags fuzz,dos
}
#examples 
#search template by author
#searchTemplateByTag author philippedelteil 
#searchTemplateByTag severity medium
#TODO: use several tagvalues
searchTemplateByTag()
{
    if [[ -z "$1" ]] | [[ -z "$2" ]]; then
        echo "Use ${FUNCNAME[0]} tagName tagValue"
        return 1
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
    if [[ -z "$1" ]] | [[ -z "$2" ]]; then
        echo "Use ${FUNCNAME[0]} version urls.txt"
        return 1
    fi
    #git repo
    gitURL="https://github.com/projectdiscovery/nuclei-templates.git"
    branch="$1"
    file="$2"
    folder="/tmp/nuclei-templates-$branch"

    if [[ -d "$folder" ]]; then
        echo "Directory $folder exists. Skipping git clone" 
    else
        git clone --depth=1 --branch $branch $gitURL $folder
    fi

    nuclei -update-directory $folder -no-update-templates -l $file
}

detectTemplatesIncorrectId()
{
   if [[ -z "$1" ]]; then
        echo "Use ${FUNCNAME[0]} detectTemplatesIncorrectId templatePath"
        echo "Example detectTemplatesIncorrectId ~/nuclei-templates"
        return 1
    fi

    templatePath="$1"
    echo "templateFileName - templateID"

    for i in $(find "$templatePath" -depth -name '*.yaml'); do 
        fname=$(basename -- "$i")
        templateName=$(echo -n "$fname"|sed 's/\.yaml//g')
        templateID=$(grep -E "^id:" "$i"|awk -F":" '{print $2}'|tr -d ' ')

        if [[ "$templateName" != "$templateID" ]];then
            echo "$templateName - $templateID"
        fi
    done
}

excludeResults()
{
    grep -v '\.lex\.\|\.lazada\.\|lazada-seller\|/lazada\|redmart\|\.asia'
}
