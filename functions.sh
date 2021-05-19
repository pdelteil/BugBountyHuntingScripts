# shell script functions to be loaded on your bashrc file 

# displays all the disabled programs in BBRF
getDisabledPrograms()
{
    for value in $(bbrf programs --show-disabled 2>/dev/null);
        do 
            disabled=$(bbrf show "$value" 2>/dev/null| jq '.disabled')
            if [ "$disabled" == "true" ] 
            then
                echo -e $value
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
    comm -3 <(sort $1) <(sort $2) > $3
}

# This function is used when adding a new program 
# it requires subfinder and assetfinder

getDomains()
{
    bbrf scope in --wildcard|bbrf inscope add -; 
    bbrf scope in --wildcard|bbrf domain add - --show-new; 
    bbrf scope in |bbrf domain add - --show-new; 
    bbrf scope in| subfinder -t 60 -silent |bbrf domain add - -s subfinder  --show-new; 
    bbrf scope in|assetfinder|bbrf domain add - -s assetfinder
}

# This function is used when adding a new program and after the getDomains function
# it requires httpx and httprobe
getUrls()
{
    RED="\e[31m"
    YELLOW="\e[33m"
    ENDCOLOR="\e[0m"

    IFS=$'\n'
    domains=$(bbrf domains|grep -v DEBUG) 
    if [ ${#domains} -gt 0 ] 
        then
            echo -en "${RED} httpx domains"        
            echo $domains |httpx -silent -threads 100 |bbrf url add - -s httpx --show-new
            echo -en "${RED} httprobe domains"        
            echo $domains |httprobe -c 50 |bbrf url add - -s httprobe --show-new
    fi
}
