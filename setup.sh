
#Global variables
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

echo -ne "${RED}\nStarting setup script${ENDCOLOR}\n\n"

#change this if you don't use bash
shellConfig="$HOME/.bashrc"
location=$(pwd)

function installTool()
{
    toolName="$1"
    installCmd="$2"
    echo -ne "${YELLOW} Checking if $toolName is out of date or not installed...${ENDCOLOR}\n"
    $installCmd
}

function addtoBashrc()
{
    helper="$1"
    configFile="$2"
    # Check if helper path is already present in config file
    count=$(grep -c "$helper" "$configFile")
    if [[ "$count" -eq 0 ]]; then
        # If not present, add the value to the file
        echo -ne "${YELLOW}Adding $helper to $configFile${ENDCOLOR}\n"
        echo "source $location/$helper " >> $configFile
    fi
}

#installing dependencies 
echo -ne "${YELLOW}Installing dependencies...${ENDCOLOR}\n\n"

installTool gcc          "sudo apt install gcc -qqq"
installTool gawk         "sudo apt install gawk"
installTool subfinder    "go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
installTool httpx        "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
installTool dnsx         "go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
installTool assetfinder  "go install -v github.com/tomnomnom/assetfinder@latest"
installTool httprobe     "go install -v github.com/tomnomnom/httprobe@master"
installTool gau          "go install -v github.com/lc/gau/v2/cmd/gau@latest"
installTool waybackurls  "go install -v github.com/tomnomnom/waybackurls@latest"
installTool amass        "go install -v github.com/OWASP/Amass/v3/...@master"
installTool unfurl       "go install -v github.com/tomnomnom/unfurl@latest"

echo  "" 
addtoBashrc bbrf_helper.sh $shellConfig
addtoBashrc nuclei_helper.sh $shellConfig
addtoBashrc general_helper.sh $shellConfig
addtoBashrc axiom_helper.sh $shellConfig
addtoBashrc amass_helper.sh $shellConfig

source $shellConfig
